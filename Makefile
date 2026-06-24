# Platform Engineering from Scratch
AWS_PROFILE ?= segoja7
AWS_REGION ?= us-east-1

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: auth
auth: ## Refresh AWS credentials for ACK (run after: aws sso login --profile segoja7)
	@aws sts get-caller-identity --profile $(AWS_PROFILE) >/dev/null 2>&1 || { \
		echo "Not authenticated. Run: aws sso login --profile $(AWS_PROFILE)"; \
		exit 1; \
	}
	@echo "Authenticated as: $$(aws sts get-caller-identity --profile $(AWS_PROFILE) --query 'Arn' --output text)"
	@kubectl delete secret aws-credentials -n ack-system --ignore-not-found
	@kubectl create secret generic aws-credentials -n ack-system \
		--from-literal=AWS_ACCESS_KEY_ID="$$(aws configure export-credentials --profile $(AWS_PROFILE) --format env-no-export | grep AWS_ACCESS_KEY_ID | cut -d= -f2)" \
		--from-literal=AWS_SECRET_ACCESS_KEY="$$(aws configure export-credentials --profile $(AWS_PROFILE) --format env-no-export | grep AWS_SECRET_ACCESS_KEY | cut -d= -f2)" \
		--from-literal=AWS_SESSION_TOKEN="$$(aws configure export-credentials --profile $(AWS_PROFILE) --format env-no-export | grep AWS_SESSION_TOKEN | cut -d= -f2)"
	@kubectl rollout restart deployment -n ack-system 2>/dev/null || true
	@echo "ACK credentials updated and controllers restarted"

.PHONY: status
status: ## Show ArgoCD apps, ACK and KRO status
	@echo "=== ArgoCD Applications ==="
	@kubectl get applications -n argocd 2>/dev/null || true
	@echo ""
	@echo "=== ACK Pods ==="
	@kubectl get pods -n ack-system 2>/dev/null || true
	@echo ""
	@echo "=== KRO ==="
	@kubectl get pods -n kro-system 2>/dev/null || true
