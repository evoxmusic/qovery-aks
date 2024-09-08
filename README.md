# AKS with Qovery

This is a simple example of how to deploy an AKS (Azure Kubernetes Service) and install Qovery on it.

## Prerequisites

- Account: [Azure](https://portal.azure.com)
- Account: [Qovery](https://console.qovery.com)
- Install: [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Install: [Terraform](https://developer.hashicorp.com/terraform/install) installed
- Install: [Qovery CLI](https://hub.qovery.com/docs/using-qovery/interface/cli/) installed

## Steps

### 1. Login to Azure

Use the Azure CLI to login to your Azure account.

```bash
az login
``` 

Once you have logged in, you can list your subscriptions.

```bash
az account list --output table
```

Then keep the `id` of the subscription you want to use.

### 2. Create an Azure Service Principal

There are many ways to authenticate to the Azure provider. In this tutorial, you will use an Active Directory service principal account. You can learn how to authenticate using a different method [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs?ajs_aid=64e31189-53fb-4675-ac81-8b1b97001d6b&product_intent=terraform#authenticating-to-azure).

First, you need to create an Active Directory service principal account using the Azure CLI. You should see something like the following.

```bash
az ad sp create-for-rbac --skip-assignment
```

The output will look like this:

```json
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "azure-cli-2021-09-01-14-47-47",
  "name": "http://azure-cli-2021-09-01-14-47-47",
  "password": "00000000-0000-0000-0000-000000000000",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

Keep the `appId` and `password` values.

### 3. Create your AKS cluster

Clone this repository and execute the following commands.

```bash
terraform init
```

Set the following environment variables.

```bash
export TF_VAR_subscription_id="00000000-0000-0000-0000-000000000000"
export TF_VAR_app_id="00000000-0000-0000-0000-000000000000"
export TF_VAR_password="00000000-0000-0000-0000-000000000000"
```

Then execute the following command to create the AKS cluster.

> You can change the values in the `main.tf` file to match your requirements.

```bash
terraform apply
```

### 3. Configure kubectl

Once the AKS cluster is created, you need to configure `kubectl` to connect to it.

```bash
az aks get-credentials --resource-group production-rg --name production --overwrite-existing
```

You should be able to see the nodes in the cluster.

```bash
kubectl get nodes
```

### 4. Install Qovery

> If you don't have a Qovery account, you can create one [here](https://console.qovery.com).

Use the Qovery CLI to login to your Qovery account.

```bash
qovery auth
```

Then generate the Helm chart to install Qovery on your AKS cluster.

```bash
qovery cluster install
```

Then, you must have a values file generated into your current directory. 


Before installing Qovery, you must edit the values file to:
1. add the following NGINX ingress value: `service.beta.kubernetes.io/azure-load-balancer-health-probe-request-pat`
2. remove the following NGINX ingress value: `service.beta.kubernetes.io/azure-load-balancer-internal`

```yaml
ingress-nginx:
  controller:
    ...
    service:
      annotations:
        ...
        #service.beta.kubernetes.io/azure-load-balancer-internal: "true"
        service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
```

You should have something like this:

```yaml
ingress-nginx:
    controller:
        allowSnippetAnnotations: true
        extraArgs:
            default-ssl-certificate: qovery/letsencrypt-acme-qovery-cert
        ingressClass: nginx-qovery
        publishService:
            enabled: true
        service:
            annotations:
                external-dns.alpha.kubernetes.io/hostname: '*.z000000.domain.tld'
                #service.beta.kubernetes.io/azure-load-balancer-internal: "true"
                service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
            enabled: true
            externalTrafficPolicy: Local
        useComponentLabel: true
    fullnameOverride: ingress-nginx
```

Now you can install the Qovery Helm repository.

```bash
helm repo add qovery https://helm.qovery.com
helm repo update
```

And install Qovery on your AKS cluster. Note that you must replace the path to the values file with your own.

```bash
helm upgrade --install --create-namespace -n qovery -f "/<REPLACE_WITH_YOUR_PATH>/my-values.yaml" --atomic \
                                       --set services.certificates.cert-manager-configs.enabled=false \
                                       --set services.certificates.qovery-cert-manager-webhook.enabled=false \
                                       --set services.qovery.qovery-cluster-agent.enabled=false \
                                       --set services.qovery.qovery-engine.enabled=false \
                                       qovery qovery/qovery
```

This operation will take a few minutes.

Then you need once again install the Helm chart but with all the services enabled.

```bash
helm upgrade --install --create-namespace -n qovery -f "/<REPLACE_WITH_YOUR_PATH>/my-values.yaml" --wait --atomic qovery qovery/qovery
```

Once it is done, you can check the status of the pods.

```bash
kubectl get pods -n qovery
```

Bravo 🥳! You have successfully installed Qovery on your AKS cluster.

### 5. Access Qovery

From the [Qovery console](https://console.qovery.com), you can access your AKS cluster and manage your applications.