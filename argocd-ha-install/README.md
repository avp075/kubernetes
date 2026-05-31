# High-Availability (HA) Argo CD Setup

Welcome! This repository contains a production-grade, highly resilient deployment configuration for **Argo CD v2.13.0**. By leveraging **Kustomize**, we extend the official Argo CD HA manifests with targeted customizations tailored for performance, custom role-based access control (RBAC), and custom user accounts.

Whether you're developing locally on Minikube or setting up a staging/production cluster, this guide will walk you through the architecture, deployment, and access methods.

---

## What's Inside? (Key Features)

This setup is built on top of the official Argo CD High-Availability manifests, designed to run without a single point of failure. Here is a breakdown of our custom overlays and improvements:

### 1. High Availability & Scalability
- **Argo CD Server:** Scaled to **3 replicas** (`argocd-server-deployment.yaml`) with `ARGOCD_API_SERVER_REPLICAS` set to `3` to handle high traffic and API load.
- **Argo CD Repo Server:** Scaled to **3 replicas** (`patches/argocd-repo-server-deployment.yaml`) to accelerate manifest generation and handle multiple concurrent Git syncs.

### 2. Tailored Configurations & Timeouts
- **Reconciliation Frequency:** Bumped `timeout.reconciliation` to `300s` (5 minutes) in `patches/argocd-cm.yaml` to reduce unnecessary polling against Git repositories, protecting API rate limits.
- **Repo Operations Timeout:** Set `ARGOCD_EXEC_TIMEOUT` to `3m` in `patches/argocd-repo-server-deployment.yaml` to ensure complex or large Helm/Kustomize builds don't fail due to network hiccups or heavy rendering times.

### 3. Custom Authentication & RBAC
- **Dedicated User Account:** A custom local user `aviral` is created, enabled for both UI login and API token generation (`apiKey, login`).
- **Secure Defaults:** The default access policy is set to `role:readonly` to keep the cluster safe by default.
- **Granular Permissions:** A custom role `role:user-update` is defined and granted to the user `aviral`, enabling them to retrieve and update user account details (`accounts` API group) while remaining read-only elsewhere.
- **Enterprise SSO Support:** The authentication and authorization (RBAC) layers can be fully integrated with **LDAP** or **Microsoft Entra ID (formerly Azure AD)** for central user authentication and mapping directory groups directly to Argo CD roles.

---

## Project Structure

Here is how the repository is structured:

```text
.
├── README.md                           # This friendly guide!
├── argocd-app.yaml                     # Self-managing Argo CD Application (App-of-Apps pattern)
├── argocd-server-deployment.yaml       # Scale patch for the core Argo CD Server deployment
├── kustomization.yaml                  # Main Kustomize orchestration file pinning Argo CD v2.13.0
├── patches/
│   ├── argocd-cm.yaml                  # ConfigMap patch: custom reconciliation timeout and user 'aviral'
│   ├── argocd-rbac-cm.yaml             # RBAC ConfigMap patch: safe read-only defaults & custom permissions
│   └── argocd-repo-server-deployment.yaml # Scale & timeout overrides for the repo server
└── resources/
    └── namespace.yaml                  # Standard namespace declaration for 'argocd'
```

---

## Getting Started

### Prerequisites
Before you start, make sure you have the following installed:
* A running Kubernetes cluster (Minikube, KinD, EKS, etc.)
* `kubectl` CLI
* `kustomize` (integrated natively in `kubectl` as `kubectl kustomize` or `-k`)

---

### Step 1: Deploy Argo CD
Deploy the entire stack with a single command. Kustomize will automatically pull the pinned `v2.13.0` HA manifests from Argo's official repository, apply our namespace definition, and lay our performance/identity patches over them.

```bash
kubectl apply -k .
```

---

### Step 2: Accessing the Argo CD Web Console

Once the pods are healthy and running, expose the web console to your local machine.

> [!NOTE]
> * **OpenShift:** You can access Argo CD by creating a `Route` object.
> * **AWS EKS:** You can expose it via an Ingress / Load Balancer and map a domain using **Route 53**.

#### Port-Forward Method
Run the following command to tunnel traffic to the `argocd-server` service:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
```
> [!TIP]
> The command above runs the port-forward in the background. You can now open your browser and go to **`https://localhost:8080`**.

#### Fetching the Initial Admin Password
To log in as the default `admin` user, fetch the auto-generated password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

> [!NOTE]
> It is highly recommended to change this password or delete the initial secret once you log in and set up your personal/SSO logins.

---

### Step 3: GitOps Self-Management (Optional but Recommended)
To implement the **App-of-Apps** pattern where Argo CD manages its own configuration from Git, apply the `argocd-app.yaml` manifest:

```bash
kubectl apply -f argocd-app.yaml
```

This ensures that any modifications made to this repository will automatically sync to your Kubernetes cluster!

---

## Auxiliary Services & Useful Commands

If you are developing locally with a broader stack (such as SonarQube or Postgres Databases) and using node port services, the following utilities will make your life much easier:

### Working with Minikube Services
If you are running on Minikube and want to easily launch/bind services, use:

```bash
minikube service <service name> -p <profile name> -n <namespace name>
```

### Quick Port-Forwarding Cheat Sheet
Here are pre-configured port forwards for common development services in your workspace:

```bash
# Forward SonarQube web interface
kubectl port-forward services/sonarqube-service 9000:9000 &

# Forward PostgreSQL database
kubectl port-forward services/db-service 5432:5432 &
```

---

## Security & Best Practices

1. **Default Read-Only Policy:** The RBAC setup relies on a strict default read-only policy. Only assign write permissions explicitly to trusted roles.
2. **Local Users:** Local accounts like `aviral` are convenient for testing and administrative work. For production use, consider integrating Argo CD with an OIDC provider (Dex, Keycloak, Okta, or GitHub OAuth).
3. **Sealed Secrets:** Never commit raw passwords or tokens directly to this repository. Use a secret manager (like HashiCorp Vault, AWS Secrets Manager, or Sealed Secrets) for GitOps safety.
