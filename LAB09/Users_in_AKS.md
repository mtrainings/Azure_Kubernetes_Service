# Users in AKS

**Exercise Overview**: This exercise focuses on creating and managing users in an Azure Kubernetes Service (AKS) cluster.

## Requirements

* Azure Subscription
* Azure CLI
* SSH Key Pair
* OpenSSL
* Base64 Encoder/Decoder

<details>
<summary><b>Solution</b></summary>
<p>

### 1. Create Resource Group

Creates an Azure Resource Group for organizing and managing resources.

```bash
az group create --location westeurope --resource-group demo-weu-rg
```

### 2. Create SSH RSA Keys

Generates SSH RSA keys for secure communication.

```bash
ssh-keygen -t rsa
```

### 3. Create Azure Kubernetes Service

Deploys an AKS cluster with specified configurations.

```bash
az aks create \
  --location westeurope \
  --subscription <Your-Subscription-ID> \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name> \
  --ssh-key-value $HOME/.ssh/id_rsa.pub \
  --network-plugin kubenet \
  --load-balancer-sku standard \
  --outbound-type loadBalancer \
  --node-vm-size Standard_B2s \
  --node-count 1 \
  --tags 'ENV=Demo' 'OWNER=Corporation Inc.'
```

### 4. Get Kubeconfig

Retrieves and merges the AKS cluster's kubeconfig into the local environment.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name> \
  --admin
```

### 5. Define Parameters

Before starting, define the following parameters:

- **USERNAME**: The name of the new user (e.g., `testuser`).
- **GROUP**: The group the user will belong to (e.g., `engineer`).
- **CLUSTER_NAME**: The name of your Kubernetes cluster.
- **CLUSTER_SERVER**: The server URL for the Kubernetes cluster.
- **CLUSTER_CA**: The certificate authority data for your cluster.
- **KUBECONFIG_PATH**: The location where the new user's kubeconfig file will be stored (e.g., `~/.kube/devops-config`).

```bash
USERNAME="testuser"
GROUP="engineer"
CLUSTER_NAME="your-cluster-name"
CLUSTER_SERVER="https://your-cluster-server"
CLUSTER_CA="your-cluster-ca"
KUBECONFIG_PATH="~/.kube/devops-config"
```

### 6. Generate the Private Key

Use OpenSSL to generate a private key for the new user:

```bash
openssl genrsa -out ${USERNAME}.key 4096
```

### 7. Generate the Certificate Signing Request (CSR)

Create a CSR for the new user using the private key:

```bash
openssl req -new -key ${USERNAME}.key -out ${USERNAME}.csr -subj "/CN=${USERNAME}/O=${GROUP}"
```

### 8. Encode the CSR in Base64

Encode the CSR in base64 format (without newlines) to make it compatible with Kubernetes:

```bash
CSR_BASE64=$(base64 < ${USERNAME}.csr | tr -d '\n')
```

### 9. Submit the CSR to Kubernetes

Submit the CSR to Kubernetes to request a certificate for the new user:

```bash
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
```

### 10. Approve the CSR

After submitting the CSR, approve it in Kubernetes:

```bash
kubectl certificate approve ${USERNAME}-csr
```

### 11. Retrieve the Signed Certificate

Once the CSR is approved, retrieve the signed certificate for the user:

```bash
CERT=$(kubectl get csr ${USERNAME}-csr -o jsonpath='{.status.certificate}')
echo "${CERT}" | base64 -d > ${USERNAME}.crt
```

### 12. Create the Kubeconfig File

Create the kubeconfig file for the new user:

```bash
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
```

### 13. Assign Permissions to the User

Now, assign necessary permissions to the new user. You can create a Role or RoleBinding for the user. For example, here is how to grant them the "view" role:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USERNAME}-view
  namespace: default
subjects:
- kind: User
  name: ${USERNAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: view
  apiGroup: rbac.authorization.k8s.io
EOF
```

## Testing

### 1. Test the New Kubeconfig

To verify that the new user's kubeconfig file is working, list the nodes in the cluster:

```bash
kubectl get nodes --kubeconfig=${KUBECONFIG_PATH}
```

This will confirm that the new user can successfully authenticate and interact with the cluster.

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>