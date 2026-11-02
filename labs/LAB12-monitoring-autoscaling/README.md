# LAB 12 – Monitoring, logs & autoscaling

> **Story:** Black Friday is coming. You need to see what CloudCart is doing (logs, metrics, control-plane audit), and it must scale out by itself – pods first, then nodes.

| | |
|---|---|
| **Duration** | ~45 min |
| **Creates** | Log Analytics workspace, Azure Monitor workspace (managed Prometheus), diagnostic setting |
| **Files** | `hpa.yaml`, `load.yaml`, `queries.kql` |

> 💰 Log Analytics is billed per GB ingested. The lab uses the default *Container insights* data collection; in production, tune it (ContainerLogV2, basic logs tier, cost presets).

## Step 1 – Container insights and managed Prometheus

```bash
source env.sh
az monitor log-analytics workspace create -g $RG -n law-$CLUSTER -l $LOCATION
LAW_ID=$(az monitor log-analytics workspace show -g $RG -n law-$CLUSTER --query id -o tsv)
az aks enable-addons -g $RG -n $CLUSTER -a monitoring --workspace-resource-id $LAW_ID
az aks update -g $RG -n $CLUSTER --enable-azure-monitor-metrics
kubectl -n kube-system get pods | grep -E "ama-logs|ama-metrics"
```

✅ **Checkpoint:** `ama-logs-*` (logs) and `ama-metrics-*` (Prometheus scraping) pods are running.

## Step 2 – Control-plane logs

The API server, scheduler and audit logs live on Microsoft's side – export them:

```bash
AKS_ID=$(az aks show -g $RG -n $CLUSTER --query id -o tsv)
az monitor diagnostic-settings create -n aks-control-plane --resource $AKS_ID --workspace $LAW_ID \
  --export-to-resource-specific true \
  --logs '[{"category":"kube-audit-admin","enabled":true},{"category":"kube-apiserver","enabled":true},{"category":"cluster-autoscaler","enabled":true},{"category":"guard","enabled":true}]'
```

`kube-audit-admin` (write operations only) is much cheaper than `kube-audit`.

## Step 3 – Quick checks with kubectl

```bash
kubectl top nodes
kubectl top pods -n cloudcart
kubectl -n cloudcart logs deploy/cloudcart-api --tail=20
kubectl get events -A --sort-by=.lastTimestamp | tail -15
```

## Step 4 – Horizontal Pod Autoscaler

```bash
kubectl apply -f labs/LAB12-monitoring-autoscaling/hpa.yaml
kubectl -n cloudcart get hpa cloudcart-api
kubectl apply -f labs/LAB12-monitoring-autoscaling/load.yaml      # 4 pods calling /burn in a loop
kubectl -n cloudcart get hpa cloudcart-api -w                      # watch TARGETS and REPLICAS, Ctrl+C after ~3 min
```

✅ **Checkpoint:** CPU above 60 % → replicas grow from 2 towards 10. Some may stay `Pending` – the nodes are full.

> The load pods call the API Service directly, which the network policy from LAB07 would block – `load.yaml` therefore runs them with the label of the gateway pods. (A shortcut for the lab – discuss why it's a bad idea in production.)

## Step 5 – Cluster autoscaler: more nodes

```bash
az aks nodepool update -g $RG --cluster-name $CLUSTER -n apps \
  --enable-cluster-autoscaler --min-count 1 --max-count 3
kubectl get nodes -w             # a new aks-apps-… node joins in ~3 min
kubectl -n cloudcart get pods -o wide | grep -c Running
```

Stop the load and watch both autoscalers scale down (pods after ~5 min, nodes after ~10 min):

```bash
kubectl delete -f labs/LAB12-monitoring-autoscaling/load.yaml
```

## Step 6 – Query logs (KQL)

Portal → AKS → **Logs** (or the Log Analytics workspace). Try the queries in `queries.kql`:

- CloudCart container logs from the last 30 minutes
- pods that restarted
- who changed what in the cluster (audit log)
- autoscaler decisions

**Metrics:** Portal → AKS → **Monitor → Metrics** / managed Prometheus; for dashboards connect **Azure Managed Grafana** to the Azure Monitor workspace (not created in the lab – extra cost).

## Discussion

- HPA on CPU vs. custom metrics → **KEDA** add-on (`--enable-keda`): scale on queue length, HTTP rate, cron.
- **Node auto-provisioning** (Karpenter-based, used by AKS Automatic): picks VM sizes per workload instead of fixed node pools.
- Alerts: Prometheus recommended alert rules, Container insights recommended alerts.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| HPA `TARGETS <unknown>` | pods have no CPU **requests**, or metrics-server not ready yet |
| no new node | autoscaler max reached, vCPU quota, or pods schedulable on existing nodes |
| no data in Logs | ingestion takes 5–10 min after enabling; check `ama-logs` pods |
| `kube-audit-admin` category missing | export-to-resource-specific tables use `AKSAuditAdmin`, not `AzureDiagnostics` |
