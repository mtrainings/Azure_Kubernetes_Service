# External Application Gateway Ingress Controller

## Requirements:

* AKS Cluster
* Application Gateway V2 + Public IP


#### Create Resource group

```bash
az group create --location westeurope \ 
   --resource-group demo-weu-rg
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

#### Create empty Application Gateway

```
az network public-ip create -g demo-weu-rg -n appgwpubip --allocation-method Static --location westeurope --sku standard
az network application-gateway create --name k8sappgw --location westeurope --resource-group demo-weu-rg --sku WAF_v2 --http-settings-cookie-based-affinity Enabled --public-ip-address appgwpubip --vnet-name k8sVnet --subnet appGWSubnet
```

#### Connect Application Gateway to AKS

```
az aks enable-addons -n myk8s -g demo-weu-rg -a ingress-appgw --appgw-id "/subscriptions/<subscription id>/resourceGroups/k8srg/providers/Microsoft.Network/applicationGateways/k8sappgw"
```

#### Deploy example application
```
kubectl apply -f example_app.yaml
```