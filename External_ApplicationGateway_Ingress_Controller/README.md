# External Application Gateway Ingress Controller

## Requirements:

* AKS Cluster
* Application Gateway V2 + Public IP


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

#### Create empty Application Gateway + VNET + SUBNET + IP

```
az network vnet create \
  --name myVNet \
  --resource-group demo-weu-rg \
  --location westeurope \
  --address-prefix 10.21.0.0/16 \
  --subnet-name myAGSubnet \
  --subnet-prefix 10.21.0.0/24
az network vnet subnet create \
  --name myBackendSubnet \
  --resource-group demo-weu-rg \
  --vnet-name myVNet   \
  --address-prefix 10.21.1.0/24
az network public-ip create \
  --resource-group demo-weu-rg \
  --name myAGPublicIPAddress \
  --allocation-method Static \
  --sku Standard
```

```
az network application-gateway create --resource-group demo-weu-rg --name AGW1 --vnet-name MyVNet --subnet myAGSubnet --public-ip-address myAGPublicIPAddress --sku Standard_v2 --capacity 1 --frontend-port 80 --http-settings-port 80 --priority 1000 
```

#### Connect Application Gateway to AKS

```
az aks enable-addons -n 1386e4a2-8f22-weu-aks -g demo-weu-rg -a ingress-appgw --appgw-id "/subscriptions/82cd7823-fbfa-4975-a9e8-b1b2201b17b3/resourceGroups/demo-weu-rg/providers/Microsoft.Network/applicationGateways/AGW1"
```

#### Deploy example application
```
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml
```
## Testing

#### Check if our ingress are updated by AKS

1. Login into azure portal go to Application Gateway and check resources after deploy application.

#### CleanUP
```bash
az group delete -n demo-weu-rg --yes --no-wait
```