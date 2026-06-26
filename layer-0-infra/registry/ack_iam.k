import kcl_helm_library.schemas

data = schemas.HelmApp {
    name = "ack-iam-controller"
    repo = "public.ecr.aws/aws-controllers-k8s"
    chart = "iam-chart"
    version = "1.7.2"
    namespace = "ack-system"
    values = r"""
aws:
  region: us-east-1
deployment:
  extraEnvVars:
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: AWS_ACCESS_KEY_ID
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: AWS_SECRET_ACCESS_KEY
    - name: AWS_SESSION_TOKEN
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: AWS_SESSION_TOKEN
"""
}
