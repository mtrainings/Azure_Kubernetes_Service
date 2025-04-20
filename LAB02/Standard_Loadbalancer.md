# Standard Load Balancer

**Exercise Overview**: Setting Up AKS Cluster with Standard Load Balancer and VM Connectivity Testing. This practical exercise guides users through the process of setting up an Azure Kubernetes Service (AKS) cluster with a Standard Load Balancer and a Virtual Machine (VM) in Azure.

## Requirements

* Azure Kubernetes Service (AKS) Cluster (Perform steps 1 to 4 if not already running)
* Standard Load Balancer
* Virtual Machine in Azure.

<details>
<summary><b>Solution</b></summary>
<p>

### 1. Create Resource Group

Creates an Azure Resource Group for organizing and managing resources.

```bash
az group create --location westeurope --resource-group demo-weu-rg
```

### 2. Create SSH RSA Keys

Generates SSH RSA keys for secure communication.

```bash
ssh-keygen -t rsa
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

### 5. Create Virtual Machine

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
  --image Ubuntu2204 \
  --nsg-rule SSH \
  --public-ip-address-allocation static \
  --public-ip-sku Standard \
  --size Standard_B2s
```

## Testing

### 1. Deploy Nginx with LoadBalancer

Create a file `nginx-lb.yaml` with the following content:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
spec:
  type: LoadBalancer
  selector:
    app: nginx-demo
  ports:
  - port: 80
    targetPort: 80
 
```

Apply it:

```bash
kubectl apply -f nginx-lb.yaml
```

### 2.Get External IP

Wait until EXTERNAL-IP is assigned.

```bash
kubectl get svc nginx-lb
```

### 3. Test from Local Machine

You should see the default Welcome to nginx! page.

```bash
curl http://<EXTERNAL-IP>
```
## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>
