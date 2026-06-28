import blueprints

# VPC networking as a KRO API, provisioned by ACK (ec2 controller).
# Builds a 2-AZ VPC: an internet gateway, public + private subnets, a single
# NAT gateway, and the route tables. KRO derives the dependency DAG from the
# ${...} status references, so resource order here does not matter.
#
# ponytail: single NAT gateway (in the first public subnet) to keep cost down.
#   Per-AZ NAT for AZ-failure resilience is deferred to Part 3 (hub-spoke).
# ponytail: fixed 2 AZs — KRO RGD resources are static templates (no loop over
#   a spec list), so subnets are declared explicitly rather than generated.
#
# Field names verified with `amdf generate <crd>.ec2.services.k8s.aws`.

# Subnet -> route-table association lives on the subnet (spec.routeTables = IDs).
_subnet = lambda id: str, azField: str, cidrField: str, public: bool, rtId: str -> {str:} {
    _roleTag = {key = "kubernetes.io/role/elb", value = "1"} if public else \
               {key = "kubernetes.io/role/internal-elb", value = "1"}
    {
        id = id
        template = {
            apiVersion = "ec2.services.k8s.aws/v1alpha1"
            kind = "Subnet"
            metadata.name = r"${schema.spec.name}-" + id
            spec = {
                vpcID = r"${vpc.status.vpcID}"
                cidrBlock = r"${schema.spec." + cidrField + r"}"
                availabilityZone = r"${schema.spec." + azField + r"}"
                mapPublicIPOnLaunch = public
                routeTables = [rtId]
                tags = [
                    {key = "Name", value = r"${schema.spec.name}-" + id}
                    _roleTag
                ]
            }
        }
    }
}

rgd = blueprints.ResourcegraphdefinitionBlueprint {
    _metadataName = "vpc-network"
    _schema = {
        apiVersion = "v1alpha1"
        kind = "VPCNetwork"
        group = "kro.run"
        spec = {
            name = "string | required=true"
            vpcCIDR = 'string | default="10.0.0.0/16"'
            az1 = 'string | default="us-east-1a"'
            az2 = 'string | default="us-east-1b"'
            publicSubnet1CIDR = 'string | default="10.0.0.0/20"'
            publicSubnet2CIDR = 'string | default="10.0.16.0/20"'
            privateSubnet1CIDR = 'string | default="10.0.32.0/20"'
            privateSubnet2CIDR = 'string | default="10.0.48.0/20"'
        }
        status = {
            vpcID = r"${vpc.status.vpcID}"
            publicSubnetIDs = [
                r"${publicSubnet1.status.subnetID}"
                r"${publicSubnet2.status.subnetID}"
            ]
            privateSubnetIDs = [
                r"${privateSubnet1.status.subnetID}"
                r"${privateSubnet2.status.subnetID}"
            ]
        }
    }
    _resources = [
        {
            id = "vpc"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "VPC"
                metadata.name = r"${schema.spec.name}"
                spec = {
                    cidrBlocks = [r"${schema.spec.vpcCIDR}"]
                    enableDNSHostnames = True
                    enableDNSSupport = True
                    tags = [{key = "Name", value = r"${schema.spec.name}"}]
                }
            }
        }
        {
            id = "internetGateway"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "InternetGateway"
                metadata.name = r"${schema.spec.name}-igw"
                spec = {
                    vpc = r"${vpc.status.vpcID}"
                    tags = [{key = "Name", value = r"${schema.spec.name}-igw"}]
                }
            }
        }
        {
            id = "eip"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "ElasticIPAddress"
                metadata.name = r"${schema.spec.name}-nat-eip"
                spec = {
                    tags = [{key = "Name", value = r"${schema.spec.name}-nat-eip"}]
                }
            }
        }
        {
            id = "publicRouteTable"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "RouteTable"
                metadata.name = r"${schema.spec.name}-public-rt"
                spec = {
                    vpcID = r"${vpc.status.vpcID}"
                    routes = [{
                        destinationCIDRBlock = "0.0.0.0/0"
                        gatewayID = r"${internetGateway.status.internetGatewayID}"
                    }]
                    tags = [{key = "Name", value = r"${schema.spec.name}-public-rt"}]
                }
            }
        }
        {
            id = "privateRouteTable"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "RouteTable"
                metadata.name = r"${schema.spec.name}-private-rt"
                spec = {
                    vpcID = r"${vpc.status.vpcID}"
                    routes = [{
                        destinationCIDRBlock = "0.0.0.0/0"
                        natGatewayID = r"${natGateway.status.natGatewayID}"
                    }]
                    tags = [{key = "Name", value = r"${schema.spec.name}-private-rt"}]
                }
            }
        }
        _subnet("publicSubnet1", "az1", "publicSubnet1CIDR", True, r"${publicRouteTable.status.routeTableID}")
        _subnet("publicSubnet2", "az2", "publicSubnet2CIDR", True, r"${publicRouteTable.status.routeTableID}")
        _subnet("privateSubnet1", "az1", "privateSubnet1CIDR", False, r"${privateRouteTable.status.routeTableID}")
        _subnet("privateSubnet2", "az2", "privateSubnet2CIDR", False, r"${privateRouteTable.status.routeTableID}")
        {
            id = "natGateway"
            template = {
                apiVersion = "ec2.services.k8s.aws/v1alpha1"
                kind = "NATGateway"
                metadata.name = r"${schema.spec.name}-nat"
                spec = {
                    allocationID = r"${eip.status.allocationID}"
                    subnetID = r"${publicSubnet1.status.subnetID}"
                    connectivityType = "public"
                    tags = [{key = "Name", value = r"${schema.spec.name}-nat"}]
                }
            }
        }
    ]
}
