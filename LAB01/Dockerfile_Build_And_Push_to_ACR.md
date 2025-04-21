# Dockerfile Build And Push to ACR

**Exercise Overview**: This exercise walks through the steps required to build a custom Docker image from a simple Node.js application and push it to Azure Container Registry (ACR). You will also configure ACR and verify the image upload.

## Requirements

* Azure CLI installed
* Docker installed and running
* Azure Container Registry (ACR)
* Node.js installed (optional – only for local test)

<details>
<summary><b>Solution</b></summary>
<p>

### 1. Create a Resource Group

Create a resource group for managing all components.

```bash
az group create --location westeurope --name docker-lab-rg
```

### 2. Create Azure Container Registry (ACR)

Replace `<acr-name>` with a globally unique name (e.g., `myacrdevopsdemo`).

```bash
az acr create --resource-group docker-lab-rg \
  --name exampleacrs \
  --sku Basic
```

### 3. Create Simple Node.js App

```bash
mkdir myapp && cd myapp
```

Create `index.js`:

```javascript
const http = require('http');
http.createServer((req, res) => {
  res.end('Hello from Docker!');
}).listen(3000);
```

Create `package.json`:

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  }
}
```

Install dependencies:

```bash
npm install
```

### 4. Create a Dockerfile

```Dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### 5. Build the Docker Image

```bash
docker build -t myapp:1.0 .
```

### 6. Login to ACR

```bash
az acr login --name <acr-name>
```

### 7. Tag the Image for ACR

```bash
docker tag myapp:1.0 <acr-name>.azurecr.io/myapp:1.0
```

### 8. Push the Image to ACR

```bash
docker push <acr-name>.azurecr.io/myapp:1.0
```

### 9. Verify the Image Exists in ACR

```bash
az acr repository list --name <acr-name> --output table
```

## Clean Up

```bash
az group delete --name docker-lab-rg --yes --no-wait
```

</p>
</details>
