# Create a Cluster with Kubenet and Standard Load Balancer

**Exercise Overview**: This exercise guides users through the process of creating an Azure Kubernetes Service (AKS) cluster using the Kubenet network plugin and a Standard Load Balancer. It covers the creation of a resource group, a service principal, and the AKS cluster itself. The users will learn how to configure and manage a basic AKS cluster with a focus on networking components.

## Requirements

* Azure Subscription
* Azure CLI
* SSH Key Pair

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

## Testing

Check if Our AKS is Up and Running

### 1. Create an example deployment

Create an example deployment

```bash
kubectl create deployment nginx --image=nginx
```

### 2. Check if the pod is up and running

```bash
kubectl get po
```

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>

# Create a Cluster Using an Existing VNET/Subnet with SSH RSA Key and Attach ACI

**Exercise Overview**: This exercise instructs users on creating an AKS cluster using an existing Virtual Network (VNET) and subnets. It covers the creation of a resource group, a service principal, and the AKS cluster itself, emphasizing integration with Azure Container Instances (ACI). Users will learn to leverage an existing network infrastructure for AKS deployment.

## Requirements

* Azure Subscription
* Azure CLI
* SSH Key Pair
* Existing VNET

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

### 3.Create VNET and Subnets

Creates an Azure Virtual Network (VNET) and two subnets: `pod-subnet` and `node-subnet`.

```bash
az network vnet create \
  --resource-group demo-weu-rg \
  --name MyVnet \
  --address-prefixes 10.0.0.0/8 \
  --output none

az network vnet subnet create \
  --resource-group demo-weu-rg \
  --vnet-name MyVnet \
  --name pod-subnet \
  --address-prefixes 10.242.0.0/16 \
  --output none

az network vnet subnet create \
  --resource-group demo-weu-rg \
  --vnet-name MyVnet \
  --name node-subnet \
  --address-prefixes 10.243.0.0/16 \
  --output none
```

### 4. Get Subnet ID

Retrieves the subnet IDs for further use in AKS cluster creation.

```bash
az network vnet subnet show \
  --resource-group demo-weu-rg \
  --vnet-name MyVnet \
  --name pod-subnet \
  --query id \
  --output tsv

az network vnet subnet show \
  --resource-group demo-weu-rg \
  --vnet-name MyVnet \
  --name node-subnet \
  --query id \
  --output tsv
```

### 5. Create Azure Kubernetes Service

**NOTE**: Replace placeholders in  `--service-principal`, and `--client-secret` with actual values.

Deploys an AKS cluster using an existing VNET and subnets, with SSH RSA key and Azure Container Instances (ACI) integration.

```bash
az aks create \
    --resource-group demo-weu-rg \
    --name <Your-AKS-Cluster-Name> \
    --vm-set-type VirtualMachineScaleSets \
    --node-vm-size Standard_B2s \
    --load-balancer-sku standard \
    --ssh-key-value $HOME/.ssh/id_rsa.pub \
    --service-principal "<Your-Service-Principal-ID>" \
    --client-secret "<Your-Client-Secret>" \
    --network-plugin "azure" \
    --network-policy "calico" \
    --vnet-subnet-id "node-subnet" \
    --pod-subnet-id "pod-subnet" \
    --node-count 1 \
    --max-pods 110
  --tags 'ENV=Demo' 'OWNER=Corporation Inc.'
```

### 6. Get Kubeconfig

Retrieves and merges the AKS cluster's kubeconfig into the local environment.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name> \
  --admin
```

## Testing

Check if Our AKS is Up and Running

### 1. Create an example deployment

Create an example deployment

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=ClusterIP --name=my-service
```

### 2. Check if the pod is up and running

```bash
kubectl get po
```

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>
