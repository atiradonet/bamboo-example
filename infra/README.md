# Infrastructure Setup

This directory contains Terraform configurations for provisioning the demo environment on GCP.

| Directory | What it creates |
|---|---|
| `gce/` | Bamboo CI server on a GCE instance behind an HTTP load balancer |
| `cloudrun/` | Cloud Run service for the application behind an HTTP load balancer |

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed and authenticated: `gcloud auth application-default login`
- Terraform >= 1.5
- Docker (to build and push the application image)

Enable the required APIs:

```bash
gcloud services enable compute.googleapis.com run.googleapis.com
```

## Step 1: Provision Bamboo

```bash
cd gce
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID
terraform init
terraform apply
```

Note the `bamboo_url` output. The Bamboo instance takes 3-5 minutes to start (it pulls the ~1 GB Bamboo Docker image on first boot). The load balancer health check may show unhealthy during this time.

## Step 2: Build and Push the Application Image

```bash
# From the repository root
docker build -t gcr.io/YOUR_PROJECT/bamboo-example-app:latest ./app
docker push gcr.io/YOUR_PROJECT/bamboo-example-app:latest
```

If using Artifact Registry instead of GCR:

```bash
gcloud artifacts repositories create bamboo-example --repository-format=docker --location=us-central1
docker tag bamboo-example-app us-central1-docker.pkg.googleapis.com/YOUR_PROJECT/bamboo-example/app:latest
docker push us-central1-docker.pkg.googleapis.com/YOUR_PROJECT/bamboo-example/app:latest
```

## Step 3: Deploy the Application

```bash
cd cloudrun
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID and image path
terraform init
terraform apply
```

Note the `app_url` output — this is the public endpoint for the application.

## Teardown

Destroy in reverse order to avoid dependency issues:

```bash
cd cloudrun && terraform destroy
cd ../gce && terraform destroy
```

Verify in the [GCP Console](https://console.cloud.google.com/) that all resources have been removed.

## Cost Estimate

Approximate monthly costs while running:

- GCE `e2-medium` instance: ~$25
- Static external IPs (x2): ~$14
- Cloud Run: scales to zero when idle (minimal cost)
- Load balancer forwarding rules (x2): ~$36

**Total: ~$75/month.** Tear down promptly when not in use.

## Notes

- **No HTTPS**: The load balancers use HTTP only. Adding TLS requires a domain name and managed certificate. This is documented as an extension point in the main README.
- **Open firewall**: The GCE firewall allows SSH and Bamboo UI access from `0.0.0.0/0`. Restrict `source_ranges` in production.
- **Local state**: Terraform state is stored locally. For shared environments, configure a GCS backend.
