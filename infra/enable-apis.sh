#!/bin/bash
set -euo pipefail

# Enable all GCP APIs required by this project.
# Run this once before provisioning any infrastructure.
#
# Usage: ./enable-apis.sh <PROJECT_ID>

PROJECT_ID="${1:?Usage: $0 <PROJECT_ID>}"

APIS=(
  compute.googleapis.com
  run.googleapis.com
  containerregistry.googleapis.com
  artifactregistry.googleapis.com
  cloudbuild.googleapis.com
  iam.googleapis.com
  cloudresourcemanager.googleapis.com
)

echo "Enabling APIs in project: ${PROJECT_ID}"
echo ""

for api in "${APIS[@]}"; do
  echo "  Enabling ${api}..."
  gcloud services enable "${api}" --project="${PROJECT_ID}"
done

echo ""
echo "All APIs enabled. Wait 1-2 minutes for propagation before running terraform."
