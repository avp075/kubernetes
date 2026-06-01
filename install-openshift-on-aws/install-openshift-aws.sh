#!/usr/bin/env bash
set -euo pipefail

# install-openshift-aws.sh
# A convenience script extracted from README.md for installing OpenShift on AWS.

# 1) Create and configure Route 53, IAM, and AWS instance manually before running this script.
# 2) Run this script from the repository root.

SSH_KEY_PATH="${HOME}/.ssh/ocp4-aws-key"
OPENSHIFT_CLIENT_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.15.8/openshift-client-linux-4.15.8.tar.gz"
OPENSHIFT_INSTALLER_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.15.8/openshift-install-linux-4.15.8.tar.gz"
INSTALL_DIR="./"

mkdir -p "${HOME}/.ssh"

if [[ ! -f "${SSH_KEY_PATH}" ]]; then
  ssh-keygen -t ed25519 -N '' -f "${SSH_KEY_PATH}"
fi

echo "Public key path: ${SSH_KEY_PATH}.pub"
cat "${SSH_KEY_PATH}.pub"

echo "Downloading OpenShift client and installer..."
curl -LO "${OPENSHIFT_CLIENT_URL}"
curl -LO "${OPENSHIFT_INSTALLER_URL}"

echo "Extracting archives..."
tar -xvf "${OPENSHIFT_CLIENT_URL##*/}"
tar -xvf "${OPENSHIFT_INSTALLER_URL##*/}"

sudo mv oc kubectl /usr/local/bin/
sudo mv openshift-install /usr/local/bin/

openshift-install version

echo "Creating install config in ${INSTALL_DIR}..."
openshift-install create install-config --dir="${INSTALL_DIR}"

echo "Installation script complete. To create the cluster, run:"
echo "  openshift-install create cluster --dir=./ --log-level=debug"
