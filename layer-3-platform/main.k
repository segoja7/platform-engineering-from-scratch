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
    # Hub EKS cluster claim. Translated from 2_hub_xcluster_claim.k.
    # ponytail: subnetIDs are placeholders — replace with real private subnet
    # IDs (Part 3 adds a VPC layer that produces them).
    {
        apiVersion = "kro.run/v1alpha1"
        kind = "EKSCluster"
        metadata = {
            name = "hub"
            namespace = "default"
        }
        spec = {
            name = "hub"
            version = "1.33"
            subnetIDs = ["subnet-REPLACE-a", "subnet-REPLACE-b"]
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
