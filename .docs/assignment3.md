# Assignment 3: IaC with Terraform & Azure

[`main.tf`](../main.tf)

[`ci-cd.yml`](../.github/workflows/ci-cd.yml)

[Azure Container Application](https://startup-nextjs.ambitioussea-7e072c94.westeurope.azurecontainerapps.io/)

## Summary of Assignment 3 Implementation

The goal of this assignment was to gain practical experience with Infrastructure as Code (IaC) using Terraform and to deploy a containerized web application in the Azure cloud. Below is a step-by-step breakdown of how I approached and solved the task.

## Step-by-Step Implementation

### Step 0: Prepare Your Environment
I logged into Azure and installed Azure CLI and Terraform.

### Step 1: Deploy Your Next.js Application
I used Terraform to deploy the Next.js application using Azure components. I created a [`main.tf`](../main.tf) file to define the infrastructure, including a resource group, a container app environment, and a container app. I used a Terraform variable to pass the container image tag to the configuration and added an output to get the fully qualified domain name (FQDN) of the container app. Additionally, I created an Azure Storage Account with an Azure Storage Container to store the Terraform state file, which is necessary for managing the state of the infrastructure and state locking, with the following commands:

```sh
#!/bin/bash

RESOURCE_GROUP_NAME=devOpsMain
STORAGE_ACCOUNT_NAME=startupnextjstfstate
CONTAINER_NAME=startupnextjstfstate

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME
```

Then I initialized Terraform and applied the configuration locally to test if the Terraform configuration was working using the following commands:

```sh
terraform init
terraform apply -var "container_image_tag=<tag of the latest container>"
```

### Step 2: Ensure Application Accessibility via DNS
I configured the application to be accessible via a DNS record by setting up the ingress in the Terraform configuration.

### Step 3: Implement Terraform Apply Step in GitHub Pipeline
I integrated the Terraform apply step into the GitHub CI/CD pipeline. The [`ci-cd.yml`](../.github/workflows/ci-cd.yml) file was updated to include jobs for building and pushing the Docker image, and applying the Terraform configuration to handle infrastructure creation, updates, and provisioning in Azure.

## Conclusion
This assignment required some research and troubleshooting as it was my first time working with Terraform, but otherwise, the assignment was quite doable except for the Azure login for Terraform. Because I was not able to create an Azure Service Principal with my Azure Student Account. I was able to create a Managed Identity, but I could not connect to the Azure Storage Account to save the Terraform state file with it. So, I ended up using `az login --use-device-code`, which unfortunately means that I have to copy a code into the browser during the pipeline. However, this was the only Azure login method that worked with my Azure Student Account. But overall, the assignment provided valuable hands-on experience with Terraform and deploying containerized applications in the Azure cloud.