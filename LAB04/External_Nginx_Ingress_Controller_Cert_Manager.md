# External Nginx Ingress Controller Cert Manager

**Exercise Overview**: External Nginx Ingress Controller with Cert Manager Setup.This exercise guides participants through the process of setting up an Azure Kubernetes Service (AKS) cluster with a Standard External Load Balancer, Nginx Ingress Controller, and Cert Manager for managing SSL certificates. The objective is to deploy a sample application with HTTPS support, ensuring secure communication.

## Requirements

* Azure Kubernetes Service (AKS) Cluster (Perform steps 1 to 4 if not already running)
* Basic Load Balancer
* Cert Manager
* Nginx Ingress Controller

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

### 5. Creating a Static IP with Azure CLI

To create a static IP in the same resource group where your AKS is deployed, you can use the following Azure CLI command:

```bash
az network public-ip create \
  --resource-group MC_demo-weu-rg_test-aks-weu_westeurope \
  --name static-ip \
  --sku Standard \
  --allocation-method Static \
  --location westeurope \
  --dns-name <my-static-ip-fqdn>
```

### 6. Create an Ingress Controller with Static IP

Sets up an Ingress Controller with a static IP using Helm charts, ensuring proper configuration for Linux nodes and Azure Load Balancer health checks.

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
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz --set controller.service.loadBalancerIP=STATIC-IP-ADDRESS
```

### 7. Check the Load Balancer Service

Monitors the Ingress Controller service to ensure successful deployment and obtain relevant details.

```bash
kubectl get services --namespace ingress-nginx -o wide -w ingress-nginx-controller
```

### 8. Deploy Cert Manager

Deploys Cert Manager using Helm charts and installs Custom Resource Definitions (CRDs).

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.0 \
  --set crds.enabled=true
```

### 9. Check Deployed Cert Manager Resources

Verifies the deployment of Cert Manager resources in the cert-manager namespace.

```bash
kubectl -n cert-manager get all
```

### 10. Deploy Cluster Issuer

1. Change the email address in `clusterissuer.yaml`.
2. Deploy the cluster issuer with the command `kubectl apply -f clusterissuer.yaml`

### 11. Deploy Sample Application and Ingress

Deploys a sample application on the AKS cluster with associated services and ingress resources.

```bash
kubectl apply -f files/deployment.yaml
kubectl apply -f files/service.yaml
kubectl apply -f files/ingress.yaml
```

## Testing

### 1.Check if SSL Certificates are Created

```bash
# Get CertificateRequests
kubectl get certificaterequest

# See the state of the request
kubectl describe certificaterequest some-certificaterequest-name

# Check the Order
kubectl get order
kubectl describe order some-order-name

# Check Challenge
kubectl get challenge
kubectl describe challenge some-challenge-name
```

### 2.Check if Domain has Proper SSL

1. Open URL "<https://<Your-AKS-Cluster-Name>.westeurope.cloudapp.azure.com/>" in browser and check SSL
2. Go to <https://www.sslshopper.com/ssl-checker.html> and check domain <Your-AKS-Cluster-Name>.westeurope.cloudapp.azure.com

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```
</p>
</details>
