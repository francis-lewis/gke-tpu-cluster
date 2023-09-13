#! /bin/bash

python3 -c "import jax; print(jax.devices())"

gcloud auth list
gke_service_account=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email)
gke_oslogin_username=$(gcloud compute os-login describe-profile | awk '/username/ {print $2}')
echo "gke service account: $gke_service_account"
echo "gke_oslogin_username: $gke_oslogin_username"

sudo gcloud auth configure-docker us-central1-docker.pkg.dev
sudo docker pull <path-to-docker-repo-here>
