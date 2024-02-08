# External Application Gateway Ingress Controller

**Exercise Overview**: External Application Gateway Ingress Controller Setup. This exercise guides participants through the process of setting up an Azure Kubernetes Service (AKS) cluster with an Application Gateway Ingress Controller, facilitating external access to applications.

## Requirements

* Azure Kubernetes Service (AKS) Cluster (Perform steps 1 to 4 if not already running)
* Application Gateway V2 + Public IP

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

### 5. Create Empty Application Gateway + VNET + SUBNET + IP

Creates an Application Gateway with a dedicated VNET, subnet, and public IP address.

```bash
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

```bash
az network application-gateway create --resource-group demo-weu-rg --name AGW1 --vnet-name MyVNet --subnet myAGSubnet --public-ip-address myAGPublicIPAddress --sku Standard_v2 --capacity 1 --frontend-port 80 --http-settings-port 80 --priority 1000 
```

### 6. Connect Application Gateway to AKS

Enables the Ingress Application Gateway add-on for AKS and associates it with the created Application Gateway.

```bash
az aks enable-addons -n <Your-AKS-Cluster-Name> -g demo-weu-rg -a ingress-appgw --appgw-id "/subscriptions/82cd7823-fbfa-4975-a9e8-b1b2201b17b3/resourceGroups/demo-weu-rg/providers/Microsoft.Network/applicationGateways/AGW1"
```

### 7. Deploy Example Application

Deploys a sample application on the AKS cluster.

```bash
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml
```

## Testing

### 1.Check if Our Ingress is Updated by AKS

1. Log in to the Azure portal, go to Application Gateway, and check resources after deploying the application.

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```
</p>
</details>