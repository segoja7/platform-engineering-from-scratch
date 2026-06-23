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
    sourceRepos=[app.repo for app in _apps]
    destination_name="in-cluster"
    destination_namespaces=[app.namespace for app in _apps]
    clusterResourceWhitelist=[
        {group = "*", kind = "*"}
    ]
)

_helm_apps = [blueprints.build_helm_app(app, project=_project.metadata.name) for app in _apps]

items = [_project] + _helm_apps
