# ArgoCD High Availability Installation

This directory contains a complete setup for deploying ArgoCD in high-availability mode on Kubernetes. It uses Kustomize to manage configuration and patches for a resilient ArgoCD deployment.

## What's Included

- **Base Configuration**: Deploys the official ArgoCD HA manifests (v2.13.0)
- **Custom Patches**: Tailored configurations for the ArgoCD server and other components
- **Namespace Management**: Automatic creation of the `argocd` namespace
- **ArgoCD Application**: Self-managed Application resource that keeps ArgoCD itself in sync

## Getting Started

### Prerequisites
- A working Kubernetes cluster (tested with minikube and production clusters)
- `kubectl` configured to access your cluster
- `kustomize` (or `kubectl apply -k` which includes kustomize)

### Installation

Deploy the entire stack using:

```bash
kubectl apply -k .
```

Or if you prefer using the ArgoCD Application resource:

```bash
kubectl apply -f argocd-app.yaml
```

## Accessing ArgoCD

### Option 1: Port Forwarding (Recommended for development)

Forward the ArgoCD server to your local machine:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
```

Then access ArgoCD at: `https://localhost:8080`

### Option 2: Using Minikube Services

If you're running on minikube, you can use:

```bash
minikube service argocd-server -n argocd -p <profile-name>
```

This will automatically open ArgoCD in your default browser.

## File Structure

- `kustomization.yaml` - Main Kustomize configuration that brings everything together
- `argocd-app.yaml` - Application resource for self-managed ArgoCD
- `argocd-server-deployment.yaml` - Patch for the ArgoCD server deployment
- `resources/` - Base Kubernetes resources (namespace, etc.)
- `patches/` - Configuration overrides for ArgoCD components:
  - `argocd-cm.yaml` - General ArgoCD settings
  - `argocd-rbac-cm.yaml` - Role-based access control rules
  - `argocd-repo-server-deployment.yaml` - Repository server configuration

## Default Credentials

After installation, the default admin username is `admin`. You'll need to retrieve the auto-generated password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Next Steps

1. Change the default admin password in ArgoCD UI
2. Connect your Git repositories to ArgoCD
3. Create Applications to deploy your workloads
4. Consider setting up RBAC for team collaboration

## Tips & Tricks

- If you're running multiple services (SonarQube, databases), you can forward multiple ports:
  ```bash
  kubectl port-forward services/sonarqube-service 9000:9000 &
  kubectl port-forward services/db-service 5432:5432 &
  ```

- Check ArgoCD status with:
  ```bash
  kubectl get pods -n argocd
  kubectl logs -n argocd deployment/argocd-server
  ```

## More Information

For more details on configuring ArgoCD, check out the [official documentation](https://argo-cd.readthedocs.io/).
