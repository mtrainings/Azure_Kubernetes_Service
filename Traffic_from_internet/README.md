# Traffic_from_internet

## Requirements:

* AKS Cluster


#### Create an ingress controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm install nginx-ingress ingress-nginx/ingress-nginx \
    --version 4.1.3 \
    --namespace ingress-basic \
    --create-namespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.image.registry=$ACR_URL \
    --set controller.image.image=ingress-nginx/controller \
    --set controller.image.tag=v1.2.1 \
    --set controller.image.digest="" \
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --set controller.admissionWebhooks.patch.image.registry=$ACR_URL \
    --set controller.admissionWebhooks.patch.image.image=ingress-nginx/kube-webhook-certgen \
    --set controller.admissionWebhooks.patch.image.tag=v1.1.1 \
    --set controller.admissionWebhooks.patch.image.digest="" \
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
    --set defaultBackend.image.registry=$ACR_URL \
    --set defaultBackend.image.image=defaultbackend-amd64 \
    --set defaultBackend.image.tag=1.5 \
    --set defaultBackend.image.digest=""
```
#### Check the load balancer service

```bash
kubectl get services --namespace ingress-basic -o wide -w ingress-nginx-controller
```

#### Deploy Application

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```