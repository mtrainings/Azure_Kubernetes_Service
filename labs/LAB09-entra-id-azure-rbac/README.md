# LAB 09 – Entra ID authentication, Azure RBAC & no local accounts

> **Story:** The auditor's verdict on LAB08: *"Shared certificates with cluster-admin rights are unacceptable."* You connect the cluster to Microsoft Entra ID, manage permissions with Azure RBAC, and switch off local accounts.

| | |
|---|---|
| **Duration** | ~40 min (work in **pairs** for Step 5) |
| **Requires** | an Entra ID group for cluster admins (create it, or ask the trainer) |
| **Files** | `rbac-entra-group.yaml` |

> ⚠️ Enabling Entra ID integration can't be undone on a cluster. That's fine here – it is the production setting.

```mermaid
flowchart LR
  U[user] -->|az login| E[Entra ID]
  U -->|kubectl + kubelogin token| API[AKS API server]
  API -->|validate token| E
  API -->|authorize| R{Kubernetes RBAC<br/>or Azure RBAC}
```

## Step 1 – Admin group and tools

```bash
source env.sh
MY_ID=$(az ad signed-in-user show --query id -o tsv)

# if you may create groups (otherwise use the group ID from the trainer):
az ad group create --display-name "aks-admins-$PREFIX" --mail-nickname "aks-admins-$PREFIX"
ADMIN_GROUP_ID=$(az ad group show --group "aks-admins-$PREFIX" --query id -o tsv)
az ad group member add --group $ADMIN_GROUP_ID --member-id $MY_ID

kubelogin --version || az aks install-cli        # kubelogin turns Entra tokens into kubectl credentials
```

## Step 2 – Enable Entra ID integration

```bash
az aks update -g $RG -n $CLUSTER --enable-aad --aad-admin-group-object-ids $ADMIN_GROUP_ID
az aks get-credentials -g $RG -n $CLUSTER --overwrite-existing
kubelogin convert-kubeconfig -l azurecli          # reuse your az login, no device code prompt
kubectl get nodes
kubectl auth whoami
```

✅ **Checkpoint:** `kubectl auth whoami` shows **your e-mail / object ID** and your groups – no more `masterclient`.

## Step 3 – Kubernetes RBAC for an Entra group

Kubernetes RBAC works as before – subjects are Entra **object IDs**:

```bash
DEV_GROUP_ID=$ADMIN_GROUP_ID      # in real life: a separate "cloudcart-devs" group
sed "s/<ENTRA-GROUP-OBJECT-ID>/$DEV_GROUP_ID/" labs/LAB09-entra-id-azure-rbac/rbac-entra-group.yaml | kubectl apply -f -
kubectl -n cloudcart get rolebinding cloudcart-developers-entra -o wide
```

## Step 4 – Azure RBAC for Kubernetes authorization

Instead of RoleBindings inside the cluster, permissions can be Azure role assignments – visible and auditable in Azure, assignable at cluster or **namespace** scope:

```bash
az aks update -g $RG -n $CLUSTER --enable-azure-rbac
AKS_ID=$(az aks show -g $RG -n $CLUSTER --query id -o tsv)
az role definition list --query "[?contains(roleName,'Azure Kubernetes Service RBAC')].roleName" -o tsv
```

Built-in roles: *RBAC Reader*, *RBAC Writer*, *RBAC Admin*, *RBAC Cluster Admin*.

## Step 5 – Give your neighbour read access to one namespace

Get your neighbour's user object ID (`az ad signed-in-user show --query id -o tsv` on their machine), then:

```bash
NEIGHBOUR_ID=<object id>
az role assignment create --assignee $NEIGHBOUR_ID --role "Azure Kubernetes Service Cluster User Role" --scope $AKS_ID
az role assignment create --assignee $NEIGHBOUR_ID --role "Azure Kubernetes Service RBAC Reader" \
  --scope $AKS_ID/namespaces/cloudcart
echo "az aks get-credentials -g $RG -n $CLUSTER --file ~/.kube/neighbour && kubelogin convert-kubeconfig -l azurecli --kubeconfig ~/.kube/neighbour"
```

Your neighbour runs the printed command, then:

```bash
kubectl --kubeconfig ~/.kube/neighbour get pods -n cloudcart     # allowed
kubectl --kubeconfig ~/.kube/neighbour get pods -n kube-system   # forbidden
kubectl --kubeconfig ~/.kube/neighbour delete pod --all -n cloudcart   # forbidden
```

✅ **Checkpoint:** read-only, one namespace – managed entirely from Azure. Role assignments can take up to 5 minutes to apply.

## Step 6 – Disable local accounts

```bash
az aks update -g $RG -n $CLUSTER --disable-local-accounts
az aks get-credentials -g $RG -n $CLUSTER --admin --file /tmp/admin2.kubeconfig     # fails now
kubectl get pods -n cloudcart --kubeconfig ~/.kube/anna.kubeconfig                   # Anna from LAB08?
```

Observe and discuss: static admin credentials are gone. What about certificates already issued (Anna)? How would you invalidate them (`az aks rotate-certs`)? What does break-glass access look like now? (an Entra group with PIM, not a stored kubeconfig)

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Insufficient privileges to complete the operation` on `az ad group create` | you can't create Entra groups – use the trainer's group |
| browser/device-code prompt on every kubectl call | run `kubelogin convert-kubeconfig -l azurecli` |
| `Forbidden` right after a role assignment | propagation delay (up to 5 min) |
| CI pipeline can't log in after Step 6 | pipelines need an Entra identity too (kubelogin with workload identity / service principal) |
