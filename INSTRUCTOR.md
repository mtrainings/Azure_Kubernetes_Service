# Instructor guide

## Before the course

1. **Subscriptions.** One subscription (or one resource group with *Owner*) per participant. Check regional vCPU quota: each participant needs ~8 vCPUs (DSv5) at peak (LAB12).
2. **Region.** Pick one with AKS, Application Gateway for Containers and availability zones (e.g. `westeurope`, `northeurope`, `swedencentral`). Set `LOCATION` in `env.sh` if you change it.
3. **Entra ID (LAB09).** Participants often can't create groups. Pre-create `aks-admins-<name>` groups (or one shared group) and add participants; hand out the object IDs.
4. **Versions.** Check `az aks get-versions`, the cert-manager and ALB Controller chart versions in `env.sh`:

   ```bash
   helm show chart oci://quay.io/jetstack/charts/cert-manager | grep ^version
   helm show chart oci://mcr.microsoft.com/application-lb/charts/alb-controller | grep ^version
   ```

5. **Accounts for LAB13/14.** GitHub account (public fork) or Azure DevOps project with permission to create service connections.
6. Do a full dry run in the course region – AKS features roll out region by region.

## Suggested schedule (3 days, 9:00–16:00)

| | Day 1 – Containers, AKS & networking | Day 2 – Ingress, security & identity | Day 3 – Storage, operations & delivery |
|---|---|---|---|
| 09:00 | Intro, containers & images | Recap | Recap |
| 09:30 | **LAB01** ACR | Gateway API & ingress options → **LAB04** | Storage → **LAB11** |
| 10:30 | ☕ | ☕ | ☕ |
| 10:45 | AKS overview, capacity, pricing | TLS → **LAB05** | Monitoring, scaling → **LAB12** |
| 11:30 | Creating clusters → **LAB02** | App Gateway for Containers → **LAB06** | 🍽 |
| 12:30 | 🍽 | 🍽 | Upgrades, BCDR, migration (slides) |
| 13:15 | Network architecture (slides) | Network policies, security → **LAB07** | GitOps → **LAB13** |
| 14:15 | Services, LB, egress → **LAB03** | Access & identity → **LAB08**, **LAB09** | CI/CD → **LAB14** |
| 15:00 | ☕ / DNS & Private Link (slides) | Workload Identity → **LAB10** | Troubleshooting → **LAB15**, Q&A |

LAB06 and LAB14 are the longest – drop one of them for a shorter class.

## Teaching notes

- **LAB02** – `--attach-acr` needs role-assignment rights; if participants are only *Contributor*, attach the ACR for them.
- **LAB04** – the App Routing Gateway API implementation (`approuting-istio`) is GA since 2026. If it's not available in your region yet, use the Istio service mesh add-on Gateway (`istio` class) – the manifests only change the `gatewayClassName`.
- **LAB05** – Let's Encrypt staging first. If outbound HTTP-01 fails, check that the DNS label resolved (Azure DNS label creation can take 1–2 min).
- **LAB06** – most failures are missing role assignments or the subnet. Verify AGC supports the cluster's network configuration (Azure CNI / CNI Overlay) in your region. AGC is billed hourly – make sure Step 7 is done.
- **LAB07** – the "site down after default deny" moment is intentional.
- **LAB09** – enabling Entra ID is irreversible; `--disable-local-accounts` breaks LAB08 credentials (that's the point). Certificates issued via the CSR API remain valid until they expire – discuss `az aks rotate-certs`.
- **LAB12** – Log Analytics ingestion costs: keep the lab short or use the "Logs and events" cost preset.
- **LAB15** – BF8 can only pass after BF4 (the client calls the bf4 Service).

## LAB15 – solutions

| # | Root cause | Fix |
|---|---|---|
| BF1 | image tag `1.O` (letter O) | `kubectl -n bf set image deploy/bf1-release api=$ACR.azurecr.io/cloudcart:1.0` |
| BF2 | `command: node app.js` – file doesn't exist | remove `command` (image default `node server.js`) |
| BF3 | requests `cpu: "6"` – no node that big | `cpu: 20m` |
| BF4 | Service selector `bf4-backend` vs pod label `bf4-api` | selector `app: bf4-api` |
| BF5 | readiness probe on port 9090 | port 8080 |
| BF6 | storage class `managed-csi-premum` (typo) | delete PVC + pod, recreate with `managed-csi-premium` (storageClassName is immutable) |
| BF7 | Role resource `pod` instead of `pods` | `resources: ["pods"]` |
| BF8 | egress policy without DNS | add egress to `kube-system` `k8s-app: kube-dns` UDP/TCP 53 (and fix BF4) |

## Cleanup check

```bash
az group list --query "[?starts_with(name,'rg-akslab-')].name" -o tsv
az keyvault list-deleted --query "[?starts_with(name,'kv-lab-')].name" -o tsv
```
