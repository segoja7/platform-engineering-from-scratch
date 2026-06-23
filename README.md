# Platform Engineering from Scratch

A cumulative blog series building a complete Kubernetes platform engineering setup. Each layer adds infrastructure and tooling that subsequent layers depend on.

## Architecture

```
Layer 0 — Base Infrastructure    Terraform (VPC, EKS, IAM)
Layer 1 — AWS Services           KRO + ACK (ECR, RDS, etc.)
Layer 2 — GitOps Engine          ArgoCD + KCL plugin
Layer 3 — Platform APIs          KeycloakStack and other CRDs
```

## Project Structure

```
.
├── layer-0-infra/          # Terraform — VPC, EKS, IAM
├── layer-1-services/       # KRO + ACK — AWS managed services
├── layer-2-gitops/         # ArgoCD + KCL plugin config
└── layer-3-platform/       # Platform CRDs (KeycloakStack, etc.)
```

## Blog Series

| Episode | Topic | Layer |
|---------|-------|-------|
| 1 | ArgoCD + KCL plugin + ECR registry | 1, 2 |
| 2 | Private EKS with networking best practices | 0 |
| 3 | Full platform on private EKS | 0, 1, 2, 3 |

## Prerequisites

- Kubernetes cluster (local or EKS)
- kubectl, helm 3
- KCL CLI
- AWS CLI with configured credentials
- Terraform (for Layer 0)

## Technologies

- **Terraform** — base infrastructure provisioning
- **KRO** — Kubernetes Resource Orchestrator for composite resources
- **ACK** — AWS Controllers for Kubernetes
- **KCL** — configuration language for generating Kubernetes manifests
- **ArgoCD** — GitOps continuous delivery
