# LAB 02 – Create the AKS cluster & deploy CloudCart

> **Story:** The platform team agreed on a modern baseline: Azure CNI Overlay with Cilium, managed identity, workload identity, Azure Linux nodes, and images pulled from your ACR without passwords. You build that cluster – it is used in **all following labs**.

| | |
|---|---|
| **Duration** | ~45 min (cluster creation ≈ 8–10 min) |
| **Creates** | AKS cluster (2 × `$NODE_SIZE`), a user node pool |
| **Files** | `cloudcart.yaml` |

## Step 1 – Check versions and quotas

```bash
source env.sh
az aks get-versions -l $LOCATION -o table                 # supported Kubernetes versions
az vm list-usage -l $LOCATION -o table | grep -i "Total Regional vCPUs\|DSv5"
```

## Step 2 – Create the cluster

```bash
az aks create \
  --resource-group $RG --name $CLUSTER --location $LOCATION \
  --tier free \
  --node-count 2 --node-vm-size $NODE_SIZE \
  --os-sku AzureLinux \
  --network-plugin azure --network-plugin-mode overlay \
  --network-dataplane cilium \
  --enable-managed-identity \
  --enable-oidc-issuer --enable-workload-identity \
  --attach-acr $ACR \
  --generate-ssh-keys \
  --tags env=training owner=$PREFIX
```

While it runs, map each flag to the slides:

| Flag | Why |
|---|---|
| `--network-plugin azure --network-plugin-mode overlay` | pods get IPs from a private overlay CIDR – no VNet IP exhaustion (the default for new clusters) |
| `--network-dataplane cilium` | eBPF dataplane + network policy enforcement (LAB07) |
| `--enable-managed-identity` | no service principal secrets to rotate |
| `--enable-oidc-issuer --enable-workload-identity` | pods get Entra ID tokens (LAB10, LAB06) |
| `--attach-acr` | grants the kubelet identity `AcrPull` on your registry |
| `--os-sku AzureLinux` | Microsoft's container-optimised node OS |

> `--attach-acr` creates a role assignment – you need *Owner* or *User Access Administrator*. If it fails, ask the trainer, or use `az aks update --attach-acr` later.

## Step 3 – Connect

```bash
az aks get-credentials -g $RG -n $CLUSTER --overwrite-existing
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

✅ **Checkpoint:** two `Ready` nodes, OS image *Azure Linux*, pods `cilium-*`, `coredns-*`, `azure-wi-webhook-*` running.

Look at the **node resource group** (`MC_…`) in the portal or with:

```bash
az aks show -g $RG -n $CLUSTER --query nodeResourceGroup -o tsv
az resource list -g $(az aks show -g $RG -n $CLUSTER --query nodeResourceGroup -o tsv) -o table
```

What lives there? (VM scale set, load balancer, public IP for egress, managed identities, VNet)

## Step 4 – Deploy CloudCart from ACR

`cloudcart.yaml` contains a namespace, a Deployment (2 replicas, probes, resource requests/limits, non-root security context) and a ClusterIP Service. The image is taken from **your** ACR:

```bash
envsubst < labs/LAB02-create-aks/cloudcart.yaml | kubectl apply -f -
kubectl -n cloudcart rollout status deploy/cloudcart-api
kubectl -n cloudcart get pods -o wide
kubectl -n cloudcart port-forward svc/cloudcart-api 8080:80 &
curl -s localhost:8080; kill %1
```

✅ **Checkpoint:** JSON with `"version": "1.0"` – the image was pulled from ACR **without** any `imagePullSecret`.

## Step 5 – Rolling update and rollback

```bash
kubectl -n cloudcart set image deploy/cloudcart-api api=$ACR.azurecr.io/cloudcart:2.0
kubectl -n cloudcart set env deploy/cloudcart-api APP_VERSION=2.0
kubectl -n cloudcart rollout status deploy/cloudcart-api
kubectl -n cloudcart rollout history deploy/cloudcart-api
kubectl -n cloudcart rollout undo deploy/cloudcart-api
```

## Step 6 – A user node pool

System pools run cluster add-ons; applications belong in **user** pools.

```bash
az aks nodepool add -g $RG --cluster-name $CLUSTER -n apps \
  --mode User --node-count 1 --node-vm-size $NODE_SIZE --os-sku AzureLinux \
  --labels workload=apps
kubectl get nodes -L workload,kubernetes.azure.com/mode
```

Pin CloudCart to it:

```bash
kubectl -n cloudcart patch deploy cloudcart-api -p '{"spec":{"template":{"spec":{"nodeSelector":{"workload":"apps"}}}}}'
kubectl -n cloudcart get pods -o wide
```

✅ **Checkpoint:** both pods run on the `aks-apps-…` node.

## Cost control

Stop the cluster when you leave for the day (keeps everything, no compute cost):

```bash
az aks stop -g $RG -n $CLUSTER      # next morning: az aks start -g $RG -n $CLUSTER
```

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `QuotaExceeded` / `OperationNotAllowed … cores` | regional vCPU quota – use a smaller `NODE_SIZE` or another region |
| `ErrImagePull` / `401 Unauthorized` from ACR | ACR not attached – `az aks update -g $RG -n $CLUSTER --attach-acr $ACR` |
| `envsubst: command not found` | `sudo apt install gettext-base` (or use Cloud Shell) |
| pods `Pending` after the nodeSelector patch | the `apps` pool isn't ready yet – `kubectl get nodes` |
