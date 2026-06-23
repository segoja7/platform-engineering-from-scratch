import kcl_helm_library.schemas

data = schemas.HelmApp {
    name = "ack-ecr-controller"
    repo = "public.ecr.aws/aws-controllers-k8s"
    chart = "ecr-chart"
    version = "1.6.2"
    namespace = "ack-system"
    values = r"""
aws:
  region: us-east-1
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ""
"""
}
