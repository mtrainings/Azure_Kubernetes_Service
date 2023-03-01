# Dynamie volumes

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
```

### Azure Disk
#### Create the PVC
```
kubectl apply -f pvc-azure-managed-disk.yaml
```
#### Mount it in a Pod
```
kubectl apply -f pod-disk.yaml
```
---
### Azure file
#### Create the PVC
```
kubectl apply -f pvc-azurefile-001.yaml
kubectl apply -f pvc-azurefile-002.yaml
```
#### Mount it in a Pod
```
kubectl apply -f pod-file-001.yaml
kubectl apply -f pod-file-002.yaml
```

#### CleanUP
```bash
az group delete -n demo-weu-rg --yes --no-wait
```
