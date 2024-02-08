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

### 2. Create Service Principal

Generates a Service Principal for AKS with the necessary permissions.

```bash
az ad sp create-for-rbac --skip-assignment -n "spn-aks"
```

### 3. Create Azure Kubernetes Service

**NOTE**: Replace placeholders in `--subscription`, `--service-principal`, and `--client-secret` with actual values.

Deploys an AKS cluster with specified configurations.

```bash
az aks create \
  --location westeurope \
  --subscription <Your-Subscription-ID> \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name> \
  --ssh-key-value $HOME/.ssh/id_rsa.pub \
  --service-principal "<Your-Service-Principal-ID>" \
  --client-secret "<Your-Client-Secret>" \
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

### 5.Generate and Approve User Certificate

Generate a private key and Certificate Signing Request (CSR) for a test user. Apply the CSR manifest, approve the CSR, and download the signed certificate.

```bash
# Generate private key
openssl genrsa -out testuser.key 4096

# Generate CSR
openssl req -new -key testuser.key -out testuser.csr -subj "/CN=testuser/O=engineer"

# Get CSR base64 encoded
cat testuser.csr | base64 | tr -d '\n'

# Apply CSR manifest and get CSR
kubectl apply -f signing-request.yaml
kubectl get csr

# Approve the CSR request and get CSR
kubectl certificate approve testuser-csr
kubectl get csr

# Download signed certificate
kubectl get csr testuser-csr -o jsonpath='{.status.certificate}' | base64 --decode > testuser.crt
cat testuser.crt

# Get the CRT base64 encoded
cat testuser.crt | base64 | tr -d '\n'

# Get the key base64 encoded
cat testuser.key | base64 | tr -d '\n'
```

### 6. Edit kubeconfig file

Edit the kubeconfig file, replacing `client-certificate-data` and `client-key-dat`a with the base64-encoded certificate and key obtained in Task 5.

## Testing

### 1. Test New kubeconfig

Ensure the updated kubeconfig file works by listing nodes in the AKS cluster.

```bash
kubectl get nodes
```

### 2. Setup RBAC for User

Apply RBAC configurations to grant specific permissions to the test user.

```bash
kubectl apply -f files/rbac-user.yaml
```

### 3. Test Permissions

Verify that the test user has the necessary permissions by listing nodes in the AKS cluster.

```bash
kubectl get nodes
```

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>
