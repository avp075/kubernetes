# Argo CD Basic Install

This workspace installs Argo CD into the `argocd` namespace using the upstream stable manifests.

## Install

Apply the kustomization:

```bash
kubectl apply -k .
```

## Port forwarding

Forward the Argo CD server to localhost:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Run in the background with `nohup`:

```bash
nohup kubectl -n argocd port-forward svc/argocd-server 8080:443 >/tmp/argocd-port-forward.log 2>&1 &
```

Then open:

```bash
http://localhost:8080
```

## Notes

- The Argo CD namespace is defined in `namespace.yaml`.
- The installation uses the upstream `install.yaml` from the Argo CD repository.
