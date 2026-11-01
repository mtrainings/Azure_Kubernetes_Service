# LAB 15 – Troubleshooting break-fix 🔧

> **Story:** Your first on-call shift. Eight tickets, one namespace, 40 minutes. Each workload in `bf` has exactly one problem.

| | |
|---|---|
| **Duration** | 30–45 min (great in pairs) |
| **Files** | `break-fix/scenarios.yaml`, `break-fix/deploy.sh`, `break-fix/check.sh` |

## Start

```bash
source env.sh
chmod +x break-fix/*.sh
./break-fix/deploy.sh
./break-fix/check.sh          # run as often as you like
```

Fix the problems in the cluster (`kubectl edit`, `kubectl patch`, or edit `scenarios.yaml` and re-apply with `./break-fix/deploy.sh`).

## The tickets

| # | Ticket | Start with |
|---|---|---|
| BF1 | *The new release never starts* | `kubectl -n bf get pods`, `describe pod` → Events |
| BF2 | *The pod restarts every few seconds* | `kubectl -n bf logs <pod> --previous` |
| BF3 | *The pod has been Pending since yesterday* | `describe pod` → `FailedScheduling` |
| BF4 | *The Service exists, but nobody answers* | `kubectl -n bf get endpointslices`, compare labels |
| BF5 | *Running, but READY 0/1 forever* | `describe pod` → readiness probe events |
| BF6 | *The database volume never shows up* | `kubectl -n bf describe pvc bf6-data`, `kubectl get sc` |
| BF7 | *The inventory job fails: forbidden* | `kubectl -n bf logs deploy/bf7-inventory`, `kubectl auth can-i … --as system:serviceaccount:bf:bf7-lister` |
| BF8 | *The app can't find any other service by name* | `kubectl -n bf logs deploy/bf8-client`, `kubectl -n bf get netpol` |

✅ **Goal:** `Score: 8 / 8`

## Your toolbox

```bash
kubectl get events -n bf --sort-by=.lastTimestamp
kubectl describe <kind> <name> -n bf
kubectl logs <pod> -n bf [--previous] [-c container]
kubectl debug -it <pod> -n bf --image=busybox:1.36 --target=<container>    # ephemeral debug container
kubectl run tmp -n bf --rm -it --image=curlimages/curl --restart=Never -- sh
kubectl auth can-i <verb> <resource> --as <user|system:serviceaccount:ns:sa>
az aks show -g $RG -n $CLUSTER --query "{state:provisioningState, power:powerState.code}"
```

Platform-level checks (no tickets, but know where to look):

- **Node NotReady** → `kubectl describe node`, AKS *Diagnose and solve problems*, `az aks nodepool show`
- **Cluster operations failing** → Activity log, `az aks show --query provisioningState`
- **Upgrade blocked** → PodDisruptionBudgets, `az aks get-upgrades`

## Wrap-up

Which of these problems could have been caught **before** reaching the cluster? (Image existence check in CI, `kubeconform`/`helm lint`, policy checks with Azure Policy/Gatekeeper, PR review of RBAC and network policies.)

Clean up: `kubectl delete namespace bf`

## After the course – delete everything

```bash
az group delete -n $RG --yes --no-wait        # cluster, node RG, ACR, Key Vault, identities
az keyvault purge -n $KV                      # soft-deleted vault (after the RG is gone)
```
