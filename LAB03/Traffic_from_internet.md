# Traffic from internet

**Exercise Overview**: Traffic from the Internet Setup with AKS and Ingress Controller. This exercise guides participants through the process of setting up an Azure Kubernetes Service (AKS) cluster with a Standard External Load Balancer and an Ingress Controller. The goal is to expose applications to the internet and test connectivity. Key steps include:

## Requirements

* Azure Kubernetes Service (AKS) Cluster (Perform steps 1 to 3 if not already running)
* Basic Load Balancer

<details>
<summary><b>Solution</b></summary>
<p>

### 1. Create Resource Group

Creates an Azure Resource Group for organizing and managing resources.

```bash
az group create --location westeurope --resource-group demo-weu-rg
```


### 2. Create Azure Kubernetes Service

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

### 3. Get Kubeconfig

Retrieves and merges the AKS cluster's kubeconfig into the local environment.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name> \
  --admin
```

### 4. Create an Ingress Controller

Sets up an Ingress Controller using Helm charts, ensuring proper configuration for Linux nodes and Azure Load Balancer health checks.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --version 4.11.5 \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=1 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

### 5. Check the Load Balancer Service

Monitors the Ingress Controller service to ensure successful deployment and obtain relevant details.

```bash
kubectl get services --namespace ingress-nginx -o wide -w ingress-nginx-controller
```

### 6. Deploy Application

Deploys a sample application on the AKS cluster with associated services and ingress resources.

```bash
kubectl apply -f files/deployment.yaml
kubectl apply -f files/service.yaml
kubectl apply -f files/ingress.yaml
```

## Testing

### 1. Open URL from Web Browser

1. <http://IP-FROM-OUR-INGRESS/>
2. <http://IP-FROM-OUR-INGRESS/hello-world-two>
3. <http://IP-FROM-OUR-INGRESS/static>

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>
