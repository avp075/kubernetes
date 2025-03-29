# jenkins Helm Chart

This Helm chart deploys jenkins using the official jenkins Community Edition Docker image.

## Installation

1. Add the Helm chart repository (if applicable).
2. Install the chart:

```bash
helm list --all-namespaces
helm install jenkins ./helm-chart-jenkins --create-namespace --namespace jenkins
helm uninstall jenkins --namespace jenkins

