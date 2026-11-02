# LAB 08 – Kubeconfig, certificate users & Kubernetes RBAC

> **Story:** Before the company connects AKS to Entra ID, the auditor wants to understand today's access model: *Who is "masterclient"? Why does every admin look the same in the logs?* Then you create a scoped user for the CloudCart developers.

| | |
|---|---|
| **Duration** | ~35 min |
| **Files** | `create-user.sh`, `rbac-cloudcart-dev.yaml` |

## Step 1 – What is inside a local kubeconfig?

```bash
source env.sh
az aks get-credentials -g $RG -n $CLUSTER --admin --file /tmp/admin.kubeconfig
az aks get-credentials -g $RG -n $CLUSTER --file /tmp/user.kubeconfig

for f in admin user; do
  echo "== $f"
  kubectl config view --kubeconfig /tmp/$f.kubeconfig --raw -o jsonpath='{.users[0].user.client-certificate-data}' \
    | base64 -d | openssl x509 -noout -subject -enddate
done
```

✅ **Checkpoint:** both certificates have the same identity, e.g. `CN = masterclient, O = system:masters` – full cluster-admin, valid for years, impossible to tell apart in audit logs, and **not revocable** individually (only by rotating the cluster CA: `az aks rotate-certs`).

```bash
kubectl auth whoami --kubeconfig /tmp/user.kubeconfig
kubectl auth can-i '*' '*' --all-namespaces --kubeconfig /tmp/user.kubeconfig
```

> Anyone with the Azure permission `Microsoft.ContainerService/managedClusters/listClusterUserCredential/action` gets this. Without Entra ID integration, guard it carefully – LAB09 fixes this properly.

## Step 2 – Create a user with a client certificate

Kubernetes has no user objects – a user is just a name in a certificate (CN) signed by the cluster CA, groups come from O.

```bash
bash labs/LAB08-kubeconfig-users-rbac/create-user.sh anna cloudcart-devs
ls ~/.kube/anna.kubeconfig
kubectl auth whoami --kubeconfig ~/.kube/anna.kubeconfig
kubectl get pods -n cloudcart --kubeconfig ~/.kube/anna.kubeconfig     # Forbidden
```

Read the script: private key → CSR (`/CN=anna/O=cloudcart-devs`) → `CertificateSigningRequest` object → `kubectl certificate approve` → kubeconfig with the signed certificate.

## Step 3 – Grant permissions with RBAC

```bash
kubectl apply -f labs/LAB08-kubeconfig-users-rbac/rbac-cloudcart-dev.yaml
K="--kubeconfig $HOME/.kube/anna.kubeconfig"
kubectl get pods -n cloudcart $K                       # allowed
kubectl -n cloudcart rollout restart deploy/cloudcart-api $K   # allowed (edit)
kubectl get secrets -n cloudcart $K                    # forbidden - custom role excludes secrets
kubectl get pods -n kube-system $K                     # forbidden
kubectl auth can-i --list -n cloudcart $K | head -20
```

✅ **Checkpoint:** Anna's group can work with workloads in `cloudcart` only, and can't read Secrets.

As admin, check what Anna can do without impersonating her certificate:

```bash
kubectl auth can-i delete deployments -n cloudcart --as anna --as-group cloudcart-devs
kubectl auth can-i get secrets -n cloudcart --as anna --as-group cloudcart-devs
```

## Step 4 – The problem with certificate users

- How do you **revoke** Anna's access when she leaves? (Delete the RoleBinding – but the certificate stays valid until it expires.)
- Where is the private key? On her laptop – plus in your shell history.
- Certificates expire – the CSR API issues them for a limited time (`spec.expirationSeconds`).

→ That is why production AKS clusters use **Entra ID** (LAB09) and disable local accounts.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| CSR stays `Pending` | not approved – `kubectl certificate approve anna-csr` |
| `error: You must be logged in to the server (Unauthorized)` | certificate/key mismatch, or kubeconfig points to a different cluster |
| `Forbidden` although bound | RoleBinding in the wrong namespace, or subject group name mismatch (`O=` in the CSR) |
