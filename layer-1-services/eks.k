import json
import blueprints

# EKS cluster as a KRO API, provisioned by ACK (iam + eks controllers).
# Translated from the Crossplane xcluster composition. KRO builds the
# dependency DAG from ${...} references, so order here does not matter.
#
# ponytail: minimal Hub cluster only. Deferred to Part 3 (hub-spoke):
#   KMS encryption, OIDC provider, security-group creation, VPC-CNI IRSA,
#   ArgoCD IRSA roles + spoke cluster secrets, the ArgoCD helm release.
# subnetIDs are an input (no VPC layer yet) — the claim passes real subnet IDs.
#
# ponytail: ACK field names are best-effort. Validate once controllers are up:
#   kubectl explain cluster.spec --api-version=eks.services.k8s.aws/v1alpha1

_cluster_assume_role = json.encode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {Service = "eks.amazonaws.com"}
        Action = "sts:AssumeRole"
    }]
})

_node_assume_role = json.encode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {Service = "ec2.amazonaws.com"}
        Action = "sts:AssumeRole"
    }]
})

# Core addons are identical except for the addon name, so one lambda builds them.
# Raw string keeps ${...} literal for KRO; KCL concatenates the static name.
_addon = lambda id: str, addonName: str -> {str:} {
    {
        id = id
        template = {
            apiVersion = "eks.services.k8s.aws/v1alpha1"
            kind = "Addon"
            metadata.name = r"${schema.spec.name}-" + addonName
            spec = {
                name = addonName
                clusterName = r"${cluster.spec.name}"
                resolveConflicts = "OVERWRITE"
            }
        }
    }
}

# vpc-cni runs on the node role's AmazonEKS_CNI_Policy (IRSA for CNI deferred to Part 3).
_addons = [
    _addon("addonPodIdentity", "eks-pod-identity-agent")
    _addon("addonVpcCni", "vpc-cni")
    _addon("addonCoredns", "coredns")
    _addon("addonKubeProxy", "kube-proxy")
]

rgd = blueprints.ResourcegraphdefinitionBlueprint {
    _metadataName = "eks-cluster"
    _schema = {
        apiVersion = "v1alpha1"
        kind = "EKSCluster"
        group = "kro.run"
        spec = {
            name = "string | required=true"
            version = 'string | default="1.33"'
            subnetIDs = "[]string"
            amiType = 'string | default="BOTTLEROCKET_x86_64"'
            capacityType = 'string | default="ON_DEMAND"'
            diskSize = "integer | default=20"
            instanceTypes = "[]string"
            desiredSize = "integer | default=1"
            minSize = "integer | default=1"
            maxSize = "integer | default=3"
            authenticationMode = 'string | default="API_AND_CONFIG_MAP"'
            endpointPublicAccess = "boolean | default=true"
            endpointPrivateAccess = "boolean | default=true"
        }
        status = {
            clusterARN = r"${cluster.status.ackResourceMetadata.arn}"
        }
    }
    _resources = [
        {
            id = "clusterRole"
            template = {
                apiVersion = "iam.services.k8s.aws/v1alpha1"
                kind = "Role"
                metadata.name = r"${schema.spec.name}-cluster-role"
                spec = {
                    name = r"${schema.spec.name}-cluster-role"
                    assumeRolePolicyDocument = _cluster_assume_role
                    policies = [
                        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
                        "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
                    ]
                }
            }
        }
        {
            id = "nodeRole"
            template = {
                apiVersion = "iam.services.k8s.aws/v1alpha1"
                kind = "Role"
                metadata.name = r"${schema.spec.name}-node-role"
                spec = {
                    name = r"${schema.spec.name}-node-role"
                    assumeRolePolicyDocument = _node_assume_role
                    policies = [
                        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
                        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
                        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
                    ]
                }
            }
        }
        {
            id = "cluster"
            template = {
                apiVersion = "eks.services.k8s.aws/v1alpha1"
                kind = "Cluster"
                metadata.name = r"${schema.spec.name}"
                spec = {
                    name = r"${schema.spec.name}"
                    roleARN = r"${clusterRole.status.ackResourceMetadata.arn}"
                    version = r"${schema.spec.version}"
                    accessConfig = {
                        authenticationMode = r"${schema.spec.authenticationMode}"
                        bootstrapClusterCreatorAdminPermissions = True
                    }
                    resourcesVPCConfig = {
                        subnetIDs = r"${schema.spec.subnetIDs}"
                        endpointPublicAccess = r"${schema.spec.endpointPublicAccess}"
                        endpointPrivateAccess = r"${schema.spec.endpointPrivateAccess}"
                    }
                    tags = {
                        ManagedBy = "kro"
                        Project = "platform-engineering-from-scratch"
                    }
                }
            }
        }
        {
            id = "nodegroup"
            template = {
                apiVersion = "eks.services.k8s.aws/v1alpha1"
                kind = "Nodegroup"
                metadata.name = r"${schema.spec.name}-ng"
                spec = {
                    name = r"${schema.spec.name}-ng"
                    clusterName = r"${cluster.spec.name}"
                    nodeRole = r"${nodeRole.status.ackResourceMetadata.arn}"
                    subnets = r"${schema.spec.subnetIDs}"
                    amiType = r"${schema.spec.amiType}"
                    capacityType = r"${schema.spec.capacityType}"
                    diskSize = r"${schema.spec.diskSize}"
                    instanceTypes = r"${schema.spec.instanceTypes}"
                    scalingConfig = {
                        desiredSize = r"${schema.spec.desiredSize}"
                        minSize = r"${schema.spec.minSize}"
                        maxSize = r"${schema.spec.maxSize}"
                    }
                }
            }
        }
    ] + _addons
}
