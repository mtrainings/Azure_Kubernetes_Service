# External Nginx Ingress Controller Cert Manager

## Requirements:

* AKS Cluster
* Standard External LoadBalancer
* Cert Manager
* Nginx Ingress Controler

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
#### Create Static IP address
```
az network public-ip create \
    --resource-group MC_demo-weu-rg_1386e4a2-8f22-weu-aks_westeurope \
    --name myStandardPublicIP \
    --version IPv4 \
    --sku Standard \
    --dns-name 1386e4a2
```
#### Create an ingress controller wtihs static IP

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm install nginx-ingress ingress-nginx/ingress-nginx \
    --version 4.1.3 \
    --namespace ingress-basic \
    --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.image.registry=$ACR_URL \
    --set controller.image.image=ingress-nginx/controller \
    --set controller.image.tag=v1.2.1 \
    --set controller.image.digest="" \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --set controller.admissionWebhooks.patch.image.registry=$ACR_URL \
    --set controller.admissionWebhooks.patch.image.image=ingress-nginx/kube-webhook-certgen \
    --set controller.admissionWebhooks.patch.image.tag=v1.1.1 \
    --set controller.admissionWebhooks.patch.image.digest="" \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.image.registry=$ACR_URL \
    --set defaultBackend.image.image=defaultbackend-amd64 \
    --set defaultBackend.image.tag=1.5 \
    --set defaultBackend.image.digest=""
```
#### Check the load balancer service

```bash
kubectl get services --namespace ingress-basic -o wide -w ingress-nginx-controller
```

#### Deploy certmanager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade cert-manager jetstack/cert-manager \
    --install \
    --create-namespace \
    --wait \
    --namespace cert-manager \
    --set installCRDs=true
```

#### Check deployed cert-manager resources

```bash
kubectl -n cert-manager get all
```

#### Deploy cluster issuer.

1. Change email address in clusterissuer.yaml
2. Deploy cluster issuer with command `kubectl apply -f clusterissuer.yaml`

#### Deploy sample application and ingress

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

#### Check if SSL are created

```
kubectl describe order quickstart-example-tls-889745041
kubectl describe challenge quickstart-example-tls-889745041-0
kubectl describe certificate quickstart-example-tls
```