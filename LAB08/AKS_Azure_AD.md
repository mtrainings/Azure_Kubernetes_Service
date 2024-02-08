# AKS + Azure AD

**Exercise Overview**: This exercise focuses on setting up an Azure Kubernetes Service (AKS) cluster with Azure Active Directory (Azure AD) integration. Azure AD integration allows for user authentication, role-based access control (RBAC), and enhanced security within AKS.

## Requirements

* Azure CLI
* kubectl
* Azure AD Account
* Azure AD Group (Admins)
* Azure AD User (Normal User)

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

### 4. Create empty AAD group for AKS Admins

Create an empty Azure AD group named "AKS-Admin" to be used for AKS administrators.

```bash
az ad group create --display-name AKS-Admin --mail-nickname AKS-Admin
```

### 5. Enable AAD integration

Update the AKS cluster to enable Azure AD integration and associate the AKS-Admin group with administrative privileges.

```bash
az aks update -g demo-weu-rg -n <Your-AKS-Cluster-Name> --enable-aad --aad-admin-group-object-ids "PROVIDE_OBJECT_ID_FROM_AAD"
```

## Testing with administrative rights

### 1. Get kubeconfig

Retrieve the kubeconfig file for AKS cluster access.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name>
```

### 2. Check nodes

Verify the availability and status of AKS cluster nodes.

```bash
kubectl get nodes
```

### 3. Add user to admin groups

Check and add a user to the AKS-Admin group for administrative privileges.

```bash
az ad group member check --group AKS-Admin --member-id "USER_OBJECT_ID"
```

### 4. Check nodes

Ensure that the user with admin privileges can access and manage AKS nodes.

```bash
kubectl get nodes
```

## Testing with normal rights

### 1. Get the AAD user id or email

Retrieve the Azure AD user's object ID or email for further configuration.

```bash
USER_ID=$(az ad user show --id UR_USER_NAME@xxxx.onmicrosoft.com --query objectId --out tsv)
```

### 2. Apply both yaml files

Apply ClusterRole and ClusterRoleBinding yaml files for role-based access control.

```bash
kubectl apply -f files/clusterrole.yaml
kubectl apply -f files/clusterrolebinding.yaml
```

### 3. Assign the user with Azure Kubernetes Service Cluster User Role

Assign the Azure Kubernetes Service Cluster User Role to the specified user, allowing them to download AKS access credentials.

```bash
az login

AKS_ID=$(az aks show --resource-group demo-weu-rg --name <Your-AKS-Cluster-Name> --query id -o tsv)

USER_ID=$(az ad user show --id UR_USER_NAME@xxxx.onmicrosoft.com --query objectId --out tsv)

az role assignment create \
  --assignee $USER_ID \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope $AKS_ID
```

### 4. Check access

Check if the user has proper access to the AKS cluster.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name>
```

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```
</p>
</details>