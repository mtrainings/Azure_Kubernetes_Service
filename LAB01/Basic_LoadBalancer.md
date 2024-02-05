# Basic Load Balancer

**Exercise Overview**: Setting Up AKS Cluster with Basic Load Balancer and VM Connectivity Testing. This practical exercise guides users through the process of setting up an Azure Kubernetes Service (AKS) cluster with a Basic Load Balancer and a Virtual Machine (VM) in Azure.

## Requirements

* Azure Kubernetes Service (AKS) Cluster (Perform steps 1 to 4 if not already running)
* Basic Load Balancer
* Virtual Machine in Azure.

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
  --load-balancer-sku basic \
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

### 5. Create SSH RSA Keys

Generates SSH RSA keys for secure communication.

```bash
ssh-keygen -t rsa
```

### 6. Create Virtual Machine

**NOTE**: Replace placeholders in `--subscription` with actual values.

Provisions a Virtual Machine with specified configurations, and wait for the VM creation to complete.

```bash
az vm create \
  --location westeurope \
  --subscription <Your-Subscription-ID> \
  --resource-group demo-weu-rg \
  --name <Your-VM-Name> \
  --ssh-key-values $HOME/.ssh/id_rsa.pub \
  --admin-username devops \
  --image UbuntuLTS \
  --nsg-rule SSH \
  --public-ip-address-allocation static \
  --public-ip-sku Basic \
  --size Standard_B2s
```

## Testing

### 1. Add Default Rule in NSG for Port 8080

Configures a Network Security Group rule to allow inbound traffic on port 8080.

```bash
az network nsg rule create \
  --resource-group demo-weu-rg \
  --nsg-name <Your-VM-NSG-Name> \
  --name AllowAnyCustom8080Inbound \
  --priority 1011 \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes '*' \
  --destination-port-ranges "8080" \
  --access Allow \
  --protocol Tcp 
```

### 2.Login via SSH to the VM and Run Netcat

Starts a netcat listener on the VM for testing connectivity.

```bash
nc -l 8080
```

### 3. Open a Second Terminal and Run Tcpdump to Inspect Packets

Captures and displays packets on port 8080 for analysis.

```bash
tcpdump -n -i eth0 port 8080
```

### 4. Deploy Example Pod

Deploys a temporary pod for testing within the AKS cluster.

```bash
kubectl run -it --rm busybox --image=busybox -- sh
```

### 5. Run Telnet Command from AKS Pod and Observe Tcpdump on VM

Tests network connectivity by initiating a telnet connection from the AKS pod to the VM on port 8080.

```bash
telnet <VM-IP-Address> 8080
```

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>
