#!/usr/bin/env bash
# Create a Kubernetes user with a client certificate signed by the cluster CA.
# Usage: create-user.sh <username> <group>
set -euo pipefail

USERNAME="${1:?username}"
GROUP="${2:?group}"
WORKDIR="$(mktemp -d)"
KUBECONFIG_OUT="${HOME}/.kube/${USERNAME}.kubeconfig"

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
  | base64 -d > "${WORKDIR}/ca.crt"

# 1. private key + certificate signing request (CN = user, O = group)
openssl genrsa -out "${WORKDIR}/${USERNAME}.key" 4096 2>/dev/null
openssl req -new -key "${WORKDIR}/${USERNAME}.key" -out "${WORKDIR}/${USERNAME}.csr" \
  -subj "/CN=${USERNAME}/O=${GROUP}"

# 2. ask the cluster to sign it (valid for 7 days)
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}-csr
spec:
  request: $(base64 < "${WORKDIR}/${USERNAME}.csr" | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 604800
  usages:
    - client auth
EOF

# 3. approve and fetch the signed certificate
kubectl certificate approve "${USERNAME}-csr"
for _ in $(seq 1 10); do
  CERT=$(kubectl get csr "${USERNAME}-csr" -o jsonpath='{.status.certificate}')
  [[ -n "${CERT}" ]] && break
  sleep 1
done
echo "${CERT}" | base64 -d > "${WORKDIR}/${USERNAME}.crt"

# 4. kubeconfig for the user
kubectl config --kubeconfig="${KUBECONFIG_OUT}" set-cluster "${CLUSTER_NAME}" \
  --server="${CLUSTER_SERVER}" --certificate-authority="${WORKDIR}/ca.crt" --embed-certs=true
kubectl config --kubeconfig="${KUBECONFIG_OUT}" set-credentials "${USERNAME}" \
  --client-certificate="${WORKDIR}/${USERNAME}.crt" --client-key="${WORKDIR}/${USERNAME}.key" --embed-certs=true
kubectl config --kubeconfig="${KUBECONFIG_OUT}" set-context "${USERNAME}@${CLUSTER_NAME}" \
  --cluster="${CLUSTER_NAME}" --user="${USERNAME}"
kubectl config --kubeconfig="${KUBECONFIG_OUT}" use-context "${USERNAME}@${CLUSTER_NAME}"

chmod 600 "${KUBECONFIG_OUT}"
rm -rf "${WORKDIR}"
echo "kubeconfig written to ${KUBECONFIG_OUT}"
openssl x509 -noout -subject -enddate -in <(kubectl config view --kubeconfig="${KUBECONFIG_OUT}" --raw \
  -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d)
