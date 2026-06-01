# SonarQube Helm Chart

This Helm chart deploys SonarQube using the official SonarQube Community Edition Docker image.

## Installation

1. Add the Helm chart repository (if applicable).
2. Install the chart:

```bash
helm list --all-namespaces
helm install sonarqube ./sonarqube-helm-chart --create-namespace --namespace sonarqube
helm uninstall sonarqube --namespace sonarqube

