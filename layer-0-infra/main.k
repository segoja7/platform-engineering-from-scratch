import kcl_helm_library.blueprints
import registry.kro
import registry.ack_ecr

_apps = [
    kro.data,
    ack_ecr.data,
]

items = [blueprints.build_helm_app(app) for app in _apps]
