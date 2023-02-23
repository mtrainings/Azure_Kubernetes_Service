# Create a cluster with kubenet and Standard LB

#### Create Resource group

```bash
az group create --location westeurope --resource-group demo-weu-rg
```

#### Create Service Principal

```bash
az ad sp create-for-rbac --skip-assignment -n "spn-aks"
```

#### Create Azure Kubernetes Service

> **_NOTE:_** We need to change --subscription, --service-principal, --client-secret

```bash
az aks create \
  --location westeurope \
  --subscription 00000000-0000-0000-0000-000000000000 \
  --resource-group demo-weu-rg \
  --name 1386e4a2-8f22-weu-aks \
  --ssh-key-value $HOME/.ssh/id_rsa.pub \
  --service-principal "00000000-0000-0000-0000-000000000000" \
  --client-secret "00000000-0000-0000-0000-000000000000" \
  --network-plugin kubenet \
  --load-balancer-sku standard \
  --outbound-type loadBalancer \
  --node-vm-size Standard_B2s \
  --node-count 1 \
  --tags 'ENV=Demo' 'OWNER=Corporation Inc.'
```

> **_NOTE:_** Now we have to wait a while until our cluster is created

#### Get kubeconfig
```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name 1386e4a2-8f22-weu-aks \
  --admin
```

## Testing

#### Check if our AKS is up and running

1. Create example deployment

```
kubectl create deployment nginx --image=nginx
```

2. Check if pod is up and running
```
kubectl get po
```

#### CleanUP
```bash
az group delete -n demo-weu-rg --yes --no-wait
```

---

# Create a cluster using an existing VNET/Subnet and SSH RSA key and attach AC

#### Create Resource group

```bash
az group create --location westeurope --resource-group demo-weu-rg
```

#### Create Service Principal

```bash
az ad sp create-for-rbac --skip-assignment -n "spn-aks"
```

#### Create VNET and subnets
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

#### Get subnet ID

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

#### Create Azure Kubernetes Service

> **_NOTE:_** We need to change --subscription, --service-principal, --client-secret, --vnet-subnet-id, --pod-subnet-id

```bash
az aks create \
    --resource-group demo-weu-rg \
    --name 1386e4a2-8f22-weu-aks \
    --vm-set-type VirtualMachineScaleSets \
    --node-vm-size Standard_B2s \
    --load-balancer-sku standard \
    --ssh-key-value $HOME/.ssh/id_rsa.pub \
    --service-principal "00000000-0000-0000-0000-000000000000" \
    --client-secret "00000000-0000-0000-0000-000000000000" \
    --network-plugin "azure" \
    --network-policy "calico" \
    --vnet-subnet-id "node-subnet" \
    --pod-subnet-id "pod-subnet" \
    --node-count 1 \
    --max-pods 110
```

> **_NOTE:_** Now we have to wait a while until our cluster is created

#### Get kubeconfig
```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name 1386e4a2-8f22-weu-aks \
  --admin
```

## Testing

#### Check if our AKS is up and running

1. Create example deployment

```
kubectl create deployment nginx --image=nginx
```

2. Check if pod is up and running
```
kubectl get po
```

#### CleanUP
```bash
az group delete -n demo-weu-rg --yes --no-wait
```