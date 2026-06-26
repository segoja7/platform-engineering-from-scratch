import blueprints
import eks

items = [eks.rgd, blueprints.ResourcegraphdefinitionBlueprint {
    _metadataName = "ecr-repository"
    _schema = {
        apiVersion = "v1alpha1"
        kind = "ECRRepository"
        group = "kro.run"
        spec = {
            name = "string | required=true"
            imageTagMutability = 'string | default="IMMUTABLE"'
            scanOnPush = "boolean | default=true"
        }
        status = {
            repositoryURI = r"${ecrRepository.status.repositoryURI}"
        }
    }
    _resources = [
        {
            id = "ecrRepository"
            template = {
                apiVersion = "ecr.services.k8s.aws/v1alpha1"
                kind = "Repository"
                metadata.name = r"${schema.spec.name}"
                spec = {
                    name = r"${schema.spec.name}"
                    imageTagMutability = r"${schema.spec.imageTagMutability}"
                    imageScanningConfiguration = {
                        scanOnPush = r"${schema.spec.scanOnPush}"
                    }
                    tags = [
                        {
                            key = "ManagedBy"
                            value = "kro"
                        }
                        {
                            key = "Project"
                            value = "platform-engineering-from-scratch"
                        }
                    ]
                }
            }
        }
    ]
}]
