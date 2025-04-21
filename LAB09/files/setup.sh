#!/bin/bash

# 1. Parameters
USERNAME="testuser"  # The username for the new Kubernetes user
GROUP="engineer"     # The group the user belongs to
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')  # Get the current cluster name
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')  # Get the server address of the cluster
CLUSTER_CA=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')  # Get the certificate authority data
KUBECONFIG_PATH="${HOME}/.kube/devops-config"  # The path where the kubeconfig will be saved

# 2. Create a private key for the new user
openssl genrsa -out ${USERNAME}.key 4096

# 3. Generate a Certificate Signing Request (CSR)
openssl req -new -key ${USERNAME}.key -out ${USERNAME}.csr -subj "/CN=${USERNAME}/O=${GROUP}"

# 4. Encode the CSR in base64 (without newlines)
CSR_BASE64=$(base64 < ${USERNAME}.csr | tr -d '\n')

# 5. Create a CSR manifest and apply it to Kubernetes to request the certificate
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USERNAME}-csr
spec:
  request: ${CSR_BASE64}
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

# 6. Approve the CSR in Kubernetes
kubectl certificate approve ${USERNAME}-csr

# 7. Retrieve the certificate from the CSR and save it to a file
CERT=$(kubectl get csr ${USERNAME}-csr -o jsonpath='{.status.certificate}')
echo "${CERT}" | base64 -d > ${USERNAME}.crt

# 8. Create a kubeconfig file from scratch for the new user
kubectl config --kubeconfig=${KUBECONFIG_PATH} set-cluster ${CLUSTER_NAME} \
  --server=${CLUSTER_SERVER} \
  --certificate-authority=<(echo "${CLUSTER_CA}" | base64 -d) \
  --embed-certs=true

kubectl config --kubeconfig=${KUBECONFIG_PATH} set-credentials ${USERNAME} \
  --client-certificate=${USERNAME}.crt \
  --client-key=${USERNAME}.key \
  --embed-certs=true

kubectl config --kubeconfig=${KUBECONFIG_PATH} set-context ${USERNAME}-context \
  --cluster=${CLUSTER_NAME} \
  --user=${USERNAME}

kubectl config --kubeconfig=${KUBECONFIG_PATH} use-context ${USERNAME}-context

# 9. Assign permissions to the user (view access to all resources)
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${USERNAME}-rolebinding
subjects:
- kind: User
  name: ${USERNAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
EOF

# 10. Test the user's access to the cluster
echo ""
echo "⏳ Testing access to the cluster as ${USERNAME}..."
sleep 5
kubectl get pods --all-namespaces --kubeconfig=${KUBECONFIG_PATH}

echo "✅ User ${USERNAME} has been successfully configured and has access to the cluster."



