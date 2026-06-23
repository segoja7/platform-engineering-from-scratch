import kcl_helm_library.schemas

data = schemas.HelmApp {
    name = "kro"
    repo = "registry.k8s.io/kro/charts"
    chart = "kro"
    version = "0.9.2"
    namespace = "kro-system"
}
