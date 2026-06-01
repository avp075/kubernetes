
# Install Openshift on AWS

This repository contains a small helper script to initialize an OpenShift installation on AWS.

## Usage

1. Configure Route 53, IAM, and the required AWS resources manually.
2. Run the helper script:

```bash
./install-openshift-aws.sh
```

3. After the script finishes, create the cluster:

```bash
openshift-install create cluster --dir=./ --log-level=debug
```

## Notes

- The script generates an SSH key at `${HOME}/.ssh/ocp4-aws-key` if it does not already exist.
- It downloads and installs the OpenShift client and installer.
- It runs `openshift-install create install-config --dir=./` to create the installation configuration.

## Example machine configuration

```yaml
compute:
  - architecture: amd64
    hyperthreading: Enabled
    name: worker
    platform: {}
    replicas: 0
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 1
```
