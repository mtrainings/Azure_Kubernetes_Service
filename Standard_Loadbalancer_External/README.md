# Standard External Load Balancer

## Requirements:

* AKS Cluster
* Standard External LoadBalancer
* Virtual Machine in Azure.

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


#### Create VM

```bash
az vm create \
  --location westeurope \
  --subscription 00000000-0000-0000-0000-000000000000 \
  --resource-group demo-weu-rg \
  --name bae6a7d275f6-weu-vm \
  --ssh-key-values $HOME/.ssh/id_rsa.pub \
  --admin-username devops \
  --image UbuntuLTS \
  --nsg-rule SSH \
  --public-ip-address-allocation static \
  --public-ip-sku Basic \
  --size Standard_B2s
```

> **_NOTE:_** Now we have to wait a while until our VM is created

---
## Testing

#### Login via SSH to the VM and run netcat

```bash
nc -l 8080
```

#### Open second terminal and run tcpdump to inspect packets 

```bash
tcpdump -n -i eth0 port 8080
```

#### Deploy example pod

```
kubectl run -it --rm busybox --image=busybox -- sh
``` 

#### Run telnet command from AKS pod and observe tcpdump on VM

```bash
telnet IP-FROM-OUR-VM 8080
```