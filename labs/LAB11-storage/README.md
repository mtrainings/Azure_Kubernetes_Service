# LAB 11 – Persistent storage: Azure Disk & Azure Files

> **Story:** CloudCart starts writing order logs and an uploads folder. Some data belongs to one pod (fast, block storage), some must be shared by all replicas. Choose the right storage class for each.

| | |
|---|---|
| **Duration** | ~35 min |
| **Files** | `statefulset-disk.yaml`, `pvc-files.yaml`, `deployment-shared.yaml` |

| | Azure Disk (`managed-csi*`) | Azure Files (`azurefile-csi*`) |
|---|---|---|
| Access mode | ReadWriteOnce – one node | ReadWriteMany – many pods/nodes |
| Use for | databases, queues, high IOPS | shared content, uploads, config |
| Zones | zonal (disk lives in one zone) | zone-redundant options |

## Step 1 – What's available?

```bash
source env.sh
kubectl get storageclass
kubectl describe storageclass managed-csi | grep -E "Provisioner|Parameters|ReclaimPolicy|VolumeBindingMode|AllowVolumeExpansion"
kubectl get csidrivers
```

Note `WaitForFirstConsumer`: the disk is created only when a pod is scheduled – in the pod's zone.

## Step 2 – Azure Disk with a StatefulSet

```bash
envsubst < labs/LAB11-storage/statefulset-disk.yaml | kubectl apply -f -
kubectl -n cloudcart get pvc,pod -l app=orders -w        # PVCs Bound, pods Running, Ctrl+C
kubectl -n cloudcart exec orders-0 -- sh -c 'wget -qO- localhost:8080/visit; wget -qO- localhost:8080/visit'
kubectl -n cloudcart delete pod orders-0                # data must survive
kubectl -n cloudcart wait --for=condition=Ready pod/orders-0 --timeout=180s
kubectl -n cloudcart exec orders-0 -- wget -qO- localhost:8080/visit
```

✅ **Checkpoint:** the visit counter continues (3) after the pod was recreated – each replica (`orders-0`, `orders-1`) has its **own** disk.

```bash
az disk list -g $(az aks show -g $RG -n $CLUSTER --query nodeResourceGroup -o tsv) -o table
```

## Step 3 – Expand a volume online

```bash
kubectl -n cloudcart patch pvc data-orders-0 -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'
kubectl -n cloudcart get pvc data-orders-0 -w
kubectl -n cloudcart exec orders-0 -- df -h /data
```

## Step 4 – Azure Files shared by several pods

```bash
kubectl apply -f labs/LAB11-storage/pvc-files.yaml
envsubst < labs/LAB11-storage/deployment-shared.yaml | kubectl apply -f -
kubectl -n cloudcart rollout status deploy/uploads
for p in $(kubectl -n cloudcart get pods -l app=uploads -o name); do kubectl -n cloudcart exec $p -- wget -qO- localhost:8080/visit; done
```

✅ **Checkpoint:** three pods on different nodes write to **one** file – the counter keeps growing across pods (ReadWriteMany).

## Step 5 – Reclaim policy

```bash
kubectl get pv -o custom-columns=NAME:.metadata.name,CLAIM:.spec.claimRef.name,POLICY:.spec.persistentVolumeReclaimPolicy
```

`Delete` (default) removes the Azure disk/share with the PVC. For data that must outlive the cluster, create a StorageClass with `reclaimPolicy: Retain` – or use static provisioning of an existing disk.

## Step 6 – Clean up

```bash
kubectl -n cloudcart delete deploy uploads
kubectl -n cloudcart delete statefulset orders
kubectl -n cloudcart delete pvc --all
```

## Discussion

- Backups: **Azure Backup for AKS** (cluster state + disk snapshots), Velero.
- Azure Container Storage for very high-performance local NVMe / ephemeral disks.
- Why are databases often better as managed Azure services than StatefulSets?

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| PVC `Pending` with *waiting for first consumer* | normal – no pod uses it yet |
| `Multi-Attach error for volume` | an RWO disk is still attached to another node (old pod terminating) |
| pod `Pending`: *volume node affinity conflict* | zonal disk in a zone without a node of the pool |
| `Permission denied` writing to Azure Files | non-root container – check `fsGroup` / mount options |
