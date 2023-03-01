# Users in AKS

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
```

#### Generate private key
```
openssl genrsa -out testuser.key 4096
```

#### Generate CSR
```
openssl req -new -key testuser.key -out testuser.csr -subj "/CN=testuser/O=engineer"
```

#### Get the CSR base64 encoded
```
cat testuser.csr | base64 | tr -d '\n'
```

#### Apply CSR manifest and get CSR
```
kubectl apply -f signing-request.yaml
kubectl get csr
```

#### Approve the CSR request and get CSR
```
kubectl certificate approve testuser-csr
kubectl get csr
```

#### Download signed certificate
````
kubectl get csr testuser-csr -o jsonpath='{.status.certificate}' | base64 --decode > testuser.crt
cat testuser.crt
````

#### Get the CRT base64 encoded
```
cat testuser.crt | base64 | tr -d '\n'
```

#### Get the key base64 encoded
```
cat testuser.key | base64 | tr -d '\n'
```

#### Edit kubeconfig file

1. Replace `client-certificate-data` and `client-key-data`

#### Test new kubeconfig
````
kubectl get nodes
````

#### Setup RBAC for user
```
kubectl apply -f rbac-user.yaml
```
#### Test permission
```
kubectl get nodes
```

#### CleanUP
```bash
az group delete -n demo-weu-rg --yes --no-wait
```