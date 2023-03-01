# AKS + Azure AD

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

#### Create empty AAD group for AKS Admins
```bash
az ad group create --display-name AKS-Admin --mail-nickname AKS-Admin
```

#### Enable AAD integration

```bash
az aks update -g demo-weu-rg -n 1386e4a2-8f22-weu-aks --enable-aad --aad-admin-group-object-ids "PROVIE_OBJECT_ID_FROM_AAD"
```

## Testing

#### Get kubeconfig
```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name 1386e4a2-8f22-weu-aks
```
#### Check nodes
```bash
kubectl get nodes
```
#### Add user to admin groups
```bash 
az ad group member check --group AKS-Admin --member-id "USER_OBJECT_ID"
```
#### Check nodes
```bash
kubectl get nodes
```

#### CleanUP
```bash
az group delete -n demo-weu-rg --yes --no-wait
```

---

# Scenario for normal user

#### Get the AAD user id or email.
```bash
USER_ID=$(az ad user show --id \
  UR_USER_NAME@xxxx.onmicrosoft.com \
  --query objectId --out tsv)
```

#### Apply both yaml files
```bash
kubectl apply -f clusterrole.yaml
kubectl apply -f clusterrolebinding.yaml
```

#### Assign the user with Azure Kubernetes Service Cluster User Role so the user can download AKS access credential.
```bash
az login

AKS_ID=$(az aks show \
  --resource-group dev-qiasphere-weu-rg \
  --name dev-qiasphere-aks \
  --query id -o tsv)

USER_ID=$(az ad user show --id \
  UR_USER_NAME@xxxx.onmicrosoft.com \
  --query objectId --out tsv)

az role assignment create \
  --assignee $USER_ID \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope $AKS_ID
```

#### Check access
```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name 1386e4a2-8f22-weu-aks
```