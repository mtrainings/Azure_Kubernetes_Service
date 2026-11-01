# LAB 01 – Container image & Azure Container Registry

> **Story:** *CloudCart* is a small online-shop backend. Your team is moving it from VMs to AKS. Step one: package the API as a secure container image and store it in a private registry.

| | |
|---|---|
| **Duration** | ~30 min |
| **Creates** | resource group, Azure Container Registry (Basic) |
| **Tools** | Azure CLI, (optional) Docker |

> 💡 Use **Azure Cloud Shell (Bash)** if you don't have the tools locally – it has `az`, `kubectl`, `helm`, `git` and `envsubst` pre-installed.

## Step 1 – Prepare the shell

```bash
git clone <this repository> aks-labs && cd aks-labs
az login                                   # skip in Cloud Shell
az account set --subscription "<your subscription>"
source env.sh                              # prints RG, CLUSTER, ACR ... - run it in every new shell
```

## Step 2 – Resource group and registry

```bash
az group create -n $RG -l $LOCATION --tags env=training owner=$PREFIX
az acr create -g $RG -n $ACR --sku Basic
az acr show -n $ACR --query loginServer -o tsv
```

✅ **Checkpoint:** the login server `acrlab<…>.azurecr.io` is printed.

## Step 3 – Read the Dockerfile

Open `app/Dockerfile` and `app/server.js`. Note:

- **multi-stage build** – dependencies installed in a build stage, runtime stage stays small
- **pinned base image** `node:22-alpine` (an LTS release) instead of `latest`
- **`USER node`** – the container doesn't run as root
- `/healthz` and `/readyz` endpoints – used by Kubernetes probes in LAB02

## Step 4 – Build in Azure (no Docker needed)

ACR Tasks builds the image in Azure from your local folder:

```bash
az acr build -r $ACR -t cloudcart:1.0 app/
```

Build a second version for later labs (rolling updates, canary):

```bash
az acr build -r $ACR -t cloudcart:2.0 app/
```

(The code is the same – the version shown by the API comes from the `APP_VERSION` environment variable set in the Deployment. In real life every tag is a new build.)

```bash
az acr repository show-tags -n $ACR --repository cloudcart -o table
```

✅ **Checkpoint:** tags `1.0` and `2.0`.

## Step 5 (optional) – The same with Docker

```bash
cd app
docker build -t cloudcart:local .
docker run --rm -d -p 8080:8080 --name cc cloudcart:local
curl -s localhost:8080 | head
docker exec cc id                      # uid=1000(node) - not root
docker stop cc

az acr login -n $ACR
docker tag cloudcart:local $ACR.azurecr.io/cloudcart:local
docker push $ACR.azurecr.io/cloudcart:local
cd ..
```

## Step 6 – Inspect the image

```bash
az acr manifest list-metadata -r $ACR -n cloudcart -o table
az acr repository show -n $ACR --image cloudcart:1.0
```

Discuss: how big is the image? How would you scan it for vulnerabilities? (Microsoft Defender for Containers scans ACR images; Trivy in CI.)

## Bonus

- Add an `org.opencontainers.image.source` label to the Dockerfile and rebuild.
- `az acr task create` – rebuild automatically when the base image `node:22-alpine` gets a security update.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `The registry name … is not available` | ACR names are global – delete `.lab-suffix`, `source env.sh` again |
| `MissingSubscriptionRegistration` | `az provider register -n Microsoft.ContainerRegistry` |
| `unauthorized` on `docker push` | run `az acr login -n $ACR` first |
