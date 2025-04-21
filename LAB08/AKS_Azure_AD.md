# AKS + Azure AD

**Exercise Overview**: This exercise focuses on setting up an Azure Kubernetes Service (AKS) cluster with Azure Active Directory (Azure AD) integration. Azure AD integration enables user authentication, role-based access control (RBAC), and enhanced security for managing AKS access.

## Requirements

* Azure CLI
* kubectl
* Azure AD Account
* Azure AD Group (Admins)
* Azure AD User (Normal User)

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

### 3. Create Azure AD Admin Group

Create an empty Azure AD group named `AKS-Admin` to be used for cluster administration.

```bash
az ad group create --display-name AKS-Admin --mail-nickname AKS-Admin
```

Retrieve its object ID:

```bash
ADMIN_GROUP_ID=$(az ad group show --group "AKS-Admin" --query id -o tsv)
```

### 4. Create AKS Cluster with Azure AD Integration

Deploy an AKS cluster and enable Azure AD integration using the admin group object ID.

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
  --tags 'ENV=Demo' 'OWNER=Corporation Inc.' \
  --enable-aad \
  --aad-admin-group-object-ids $ADMIN_GROUP_ID
```

## Testing with Administrative Rights

### 1. Get kubeconfig

Retrieve the kubeconfig file for AKS cluster access.

```bash
az aks get-credentials \
  --resource-group demo-weu-rg \
  --name <Your-AKS-Cluster-Name> --admin

```

### 2. Check nodes

Verify cluster node status.

```bash
kubectl get nodes
```

### 3. Add user to admin group

Add a user to the AKS-Admin group to grant admin access.

```bash
az ad group member add --group AKS-Admin --member-id db2fd2b7-c593-414f-834c-c231487605c6
```

Check membership:

```bash
az ad group member check --group AKS-Admin --member-id db2fd2b7-c593-414f-834c-c231487605c6
```

### 4. Verify access

Log in as the added user and confirm access to the cluster:

```bash
kubectl get nodes
```



## Testing with Normal User Rights

### 1. Get AAD user object ID

```bash
USER_ID=$(az ad user show --id test-user@contactthinkcube.onmicrosoft.com --query objectId -o tsv)
```



### 2. Apply YAML definitions

Apply the ClusterRole and ClusterRoleBinding definitions for basic read access.

`clusterrole.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: readonly-role
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "watch", "list"]
```

`clusterrolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: readonly-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: readonly-role
subjects:
- kind: User
  name: username@yourtenant.onmicrosoft.com  # or use objectId
  apiGroup: rbac.authorization.k8s.io
```

Apply the manifests:

```bash
kubectl apply -f files/clusterrole.yaml
kubectl apply -f files/clusterrolebinding.yaml
```



### 3. Assign Cluster User Role

Allow the user to obtain kubeconfig credentials.

```bash
AKS_ID=$(az aks show --resource-group demo-weu-rg --name <Your-AKS-Cluster-Name> --query id -o tsv)

az role assignment create   --assignee $USER_ID   --role "Azure Kubernetes Service Cluster User Role"   --scope $AKS_ID
```



### 4. Check access

As the normal user:

```bash
az aks get-credentials   --resource-group demo-weu-rg   --name <Your-AKS-Cluster-Name>
```

Try running:

```bash
kubectl get pods --all-namespaces
kubectl delete  po --all  -n kube-system
```

Expected: Limited access only (read-only for listed resources).



## Clean Up

### 1. Delete all resources

```bash
az group delete -n demo-weu-rg --yes --no-wait
```

</p>
</details>