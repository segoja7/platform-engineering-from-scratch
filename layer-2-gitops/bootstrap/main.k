import kcl_helm_library.blueprints

_project = blueprints.build_project(
    name="platform-bootstrap"
    description="Bootstrap - ArgoCD watches the platform repo and deploys all layers"
    annotations={}
    sourceRepos=["https://github.com/segoja7/platform-engineering-from-scratch"]
    destination_name="in-cluster"
    destination_namespaces=["argocd", "kro-system", "ack-system", "default"]
    clusterResourceWhitelist=[
        {group = "*", kind = "*"}
    ]
)

_bootstrap_app = blueprints.ApplicationBlueprint {
    _metadataName = "layer-0-infra"
    _namespace = "argocd"
    _destination = {
        name = "in-cluster"
        namespace = "argocd"
    }
    _project = _project.metadata.name
    _source = {
        repoURL = "https://github.com/segoja7/platform-engineering-from-scratch"
        targetRevision = "main"
        path = "layer-0-infra"
        plugin = {}
    }
    _syncPolicy = {
        automated = {
            prune = True
            selfHeal = True
        }
        syncOptions = [
            "CreateNamespace=true"
        ]
    }
}

_layer1_app = blueprints.ApplicationBlueprint {
    _metadataName = "layer-1-services"
    _namespace = "argocd"
    _destination = {
        name = "in-cluster"
        namespace = "default"
    }
    _project = _project.metadata.name
    _source = {
        repoURL = "https://github.com/segoja7/platform-engineering-from-scratch"
        targetRevision = "main"
        path = "layer-1-services"
        plugin = {}
    }
    _syncPolicy = {
        automated = {
            prune = True
            selfHeal = True
        }
        syncOptions = [
            "CreateNamespace=true"
        ]
    }
}

items = [_project, _bootstrap_app, _layer1_app]
