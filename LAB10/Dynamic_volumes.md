# Dynamie volumes

**Exercise Overview**: This exercise focuses on utilizing dynamic volumes in Azure Kubernetes Service (AKS). You'll go through the process of creating a resource group, provisioning a service principal, setting up an AKS cluster, and implementing dynamic volumes using Azure Disk and Azure File.

## Requirements

* Azure Subscription
* Azure Kubernetes Service (AKS) Cluster (Perform steps 1 to 4 if not already running)
* Azure CLI
* SSH Key Pair

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

## Testing (Azure Disk)

### 1. Create the PVC and Mount it in a Pod

Implement a Persistent Volume Claim (PVC) for Azure Disk and mount it within a pod.

```bash
kubectl apply -f files/pvc-azure-managed-disk.yaml
kubectl apply -f files/pod-disk.yaml
```

### 2. Check PVC and Pod Status

Verify that the PVC is bound and the Pod is running.Ensure the PVC is in a `Bound` state and the Pod is in a `Running` state.

```bash
kubectl get pvc
kubectl get pods
```

### 3. Log into Pod

Enter the Pod to verify if the Azure Disk is mounted correctly. Replace `<pod-name>` with the actual name of your Pod.

```bash
kubectl exec -it <pod-name> -- /bin/bash
```

### 4. Check Mounted Disk

Inside the Pod, check if the Azure Disk is mounted:

```bash
df -h
```

---

## Testing (Azure File)

### 1. Create the PVCs and Mount them in Pods

Set up Persistent Volume Claims (PVCs) for Azure File and mount them in respective pods.

```bash
kubectl apply -f files/pvc-azurefile-001.yaml
kubectl apply -f files/pvc-azurefile-002.yaml
kubectl apply -f files/pod-file-001.yaml
kubectl apply -f files/pod-file-002.yaml
```

### 2. Check PVC and Pod Status

Verify that the PVCs are bound, and the Pods are running. Ensure the PVCs are in a `Bound` state, and the Pods are in a `Running` state.

```bash
kubectl get pvc
kubectl get pods
```

### 3. Log into Pods

Enter the Pods to verify if the Azure Files are mounted correctly. Replace `<pod-file-001-name>` and `<pod-file-002-name>` with the actual names of your Pods.

```bash
kubectl exec -it <pod-file-001-name> -- /bin/bash
kubectl exec -it <pod-file-002-name> -- /bin/bash
```

### 4. Check Mounted Files

Inside the Pods, check if the Azure Files are mounted

```bash
df -h
```

## Clean Up

### 1. Remove all resources

Deletes the resource group and associated resources.

```bash
az group delete -n demo-weu-rg --yes --no-wait
```
</p>
</details>