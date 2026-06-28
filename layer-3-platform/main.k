items = [
    {
        apiVersion = "kro.run/v1alpha1"
        kind = "ECRRepository"
        metadata = {
            name = "kcl-modules"
            namespace = "default"
        }
        spec = {
            name = "kcl-modules"
        }
    }
    # Hub VPC networking claim. Produces vpcID + public/private subnet IDs in
    # its status once provisioned.
    {
        apiVersion = "kro.run/v1alpha1"
        kind = "VPCNetwork"
        metadata = {
            name = "hub"
            namespace = "default"
        }
        spec = {
            name = "hub"
            vpcCIDR = "10.0.0.0/16"
            az1 = "us-east-1a"
            az2 = "us-east-1b"
        }
    }
    # Hub EKS cluster claim. Translated from 2_hub_xcluster_claim.k.
    # networkName points at the VPCNetwork "hub" above; ACK resolves the cluster
    # and nodegroup subnetRefs to its private subnet IDs automatically.
    {
        apiVersion = "kro.run/v1alpha1"
        kind = "EKSCluster"
        metadata = {
            name = "hub"
            namespace = "default"
        }
        spec = {
            name = "hub"
            version = "1.36"
            networkName = "hub"
            amiType = "BOTTLEROCKET_x86_64"
            capacityType = "ON_DEMAND"
            diskSize = 20
            instanceTypes = ["m7i-flex.large"]
            minSize = 1
            maxSize = 3
            desiredSize = 1
            authenticationMode = "API_AND_CONFIG_MAP"
            endpointPublicAccess = True
            endpointPrivateAccess = True
        }
    }
]
