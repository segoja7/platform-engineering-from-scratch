import kcl_helm_library.blueprints
import registry.kro
import registry.ack_ecr

_apps = [
    kro.data,
    ack_ecr.data,
]

_project = blueprints.build_project(
    name="platform-base"
    description="Platform Engineering - Base Infrastructure (KRO + ACK)"
    annotations={}
    sourceRepos=[app.repo for app in _apps] + ["https://github.com/segoja7/platform-engineering-from-scratch"]
    destination_name="in-cluster"
    destination_namespaces=[app.namespace for app in _apps] + ["default"]
    clusterResourceWhitelist=[
        {group = "*", kind = "*"}
    ]
)

_helm_apps = [blueprints.build_helm_app(app, project=_project.metadata.name) for app in _apps]

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

_platform_project = blueprints.build_project(
    name="platform-apis"
    description="Platform APIs - Claims that consume infrastructure services"
    annotations={}
    sourceRepos=["https://github.com/segoja7/platform-engineering-from-scratch"]
    destination_name="in-cluster"
    destination_namespaces=["default"]
    clusterResourceWhitelist=[
        {group = "kro.run", kind = "*"}
    ]
)

_layer3_app = blueprints.ApplicationBlueprint {
    _metadataName = "layer-3-platform"
    _namespace = "argocd"
    _destination = {
        name = "in-cluster"
        namespace = "default"
    }
    _project = _platform_project.metadata.name
    _source = {
        repoURL = "https://github.com/segoja7/platform-engineering-from-scratch"
        targetRevision = "main"
        path = "layer-3-platform"
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

items = [_project, _platform_project] + _helm_apps + [_layer1_app, _layer3_app]
