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

## Testing

### 1. Generate kubeconfig (get-credentials) for Admins

After successfully provisioning the Azure Kubernetes Service (AKS) cluster, it's essential to create a kubeconfig file specifically tailored for administrators. This file contains the necessary credentials and configuration settings to access the AKS cluster with administrative privileges.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name> \
  --file ./<Your-AKS-Cluster-Name>-admin.kubeconfig \
  --admin
```

Running this command will fetch the credentials for the AKS cluster and save them in a kubeconfig file named `<Your-AKS-Cluster-Name>-admin.kubeconfig`. Administrators can then use this file to interact with the AKS cluster, allowing them to perform tasks that require elevated permissions.

### 2. Generate kubeconfig (get-credentials) for Users

To facilitate secure access for regular users to the AKS cluster, a separate kubeconfig file needs to be generated. This file contains the necessary credentials and configurations for users to interact with the AKS cluster within the bounds of their assigned permissions.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name> \
  --file ./386e4a2-8f22-weu-aks-user.kubeconfig
```

Running this command will fetch the credentials for the AKS cluster and save them in a kubeconfig file named `<Your-AKS-Cluster-Name>-user.kubeconfig`. Users can utilize this file to perform tasks on the AKS cluster based on the permissions granted to their respective roles. Separating admin and user kubeconfig files ensures a granular and secure approach to cluster access.

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>