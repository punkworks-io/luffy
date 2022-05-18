#!/bin/bash

set -eu

echo ""
echo "Preparing to execute with the following values:"
echo "==================================================="
echo "GCP Admin Project: ${GCP_admin_project:?}"
echo "Luffy Service Account on GCP: ${GCP_luffy_service_account_name:?}"
echo "Service account credentials path: ${GCP_luffy_service_account_credentials:?}"
echo "==================================================="
echo ""
echo "Continuing in 10 seconds. Ctrl+C to cancel if you change your mind"

sleep 10

echo "=> Creating Luffy service account"
gcloud iam service-accounts create ${GCP_luffy_service_account_name} \
  --display-name "Luffy Service Account" \
  --project "${GCP_admin_project}"


echo "=> Creating service account keys and saving to ${GCP_luffy_service_account_credentials}"
gcloud iam service-accounts keys create "${GCP_luffy_service_account_credentials}" \
  --iam-account "${GCP_luffy_service_account_name}@${GCP_admin_project}.iam.gserviceaccount.com"

echo "=> Binding IAM roles to service account"

# Add Viewer permissions for the Admin project
gcloud projects add-iam-policy-binding "${GCP_admin_project}" \
  --member "serviceAccount:${GCP_luffy_service_account_name}@${GCP_admin_project}.iam.gserviceaccount.com" \
  --role roles/viewer


# Add Container cluster admin permissions to entire Folder
gcloud resource-manager folders add-iam-policy-binding "${GCP_folder_id}" \
  --member "serviceAccount:${GCP_luffy_service_account_name}@${GCP_admin_project}.iam.gserviceaccount.com" \
  --role roles/container.admin




gcloud projects add-iam-policy-binding "${GCP_test_project}" \
  --member "serviceAccount:${GCP_luffy_service_account_name}@${GCP_admin_project}.iam.gserviceaccount.com" \
  --role roles/container.admin

gcloud projects add-iam-policy-binding "${GCP_production_project}" \
  --member "serviceAccount:${GCP_luffy_service_account_name}@${GCP_admin_project}.iam.gserviceaccount.com" \
  --role roles/container.admin



echo ""
echo "GCP service account for Luffy set up successfully"
echo ""

echo "gcloud auth activate-service-account --key-file=${export GCP_luffy_service_account_credentials}"