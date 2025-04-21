# AKS_Authorization

**Exercise Overview**: This exercise focuses on establishing secure and role-based access to an Azure Kubernetes Service (AKS) cluster. It covers key steps, including creating a resource group, generating a service principal, deploying the AKS cluster with specific configurations, and creating kubeconfig files for both administrators and regular users.

## Requirements

* Azure Subscription
* Azure CLI

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

## Testing

### 1. Generate kubeconfig

After successfully provisioning the Azure Kubernetes Service (AKS) cluster, it's essential to create a kubeconfig file specifically tailored for administrators. This file contains the necessary credentials and configuration settings to access the AKS cluster with administrative privileges.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name test-aks-weu \
  --file .test-aks-weu-admin.kubeconfig \
  --admin
```

Running this command will fetch the credentials for the AKS cluster and save them in a kubeconfig file named `<Your-AKS-Cluster-Name>-admin.kubeconfig`. Administrators can then use this file to interact with the AKS cluster, allowing them to perform tasks that require elevated permissions.

### 2. Check cluster access

To verify that the kubeconfig file provides proper admin access, execute the following tests:

```bash
kubectl get nodes --kubeconfig .test-aks-weu-admin.kubeconfig
```

### 3. Check access to kube-system namespace

```bash
kubectl get pods -n kube-system --kubeconfig .test-aks-weu-admin.kubeconfig
```

### 4. Check if you can read clusterrolebindings

```bash
kubectl get clusterrolebindings --kubeconfig .test-aks-weu-admin.kubeconfig
```

### 5. Check your permissions (impersonating yourself)

```bash
kubectl auth can-i '*' '*' --all-namespaces -kubeconfig .test-aks-weu-admin.kubeconfig
```

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>