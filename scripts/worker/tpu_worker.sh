#! /bin/bash

gke_service_account=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email)
gke_oslogin_username=$(gcloud compute os-login describe-profile | awk '/username/ {print $2}')
echo "gke service account: $gke_service_account"
echo "gke_oslogin_username: $gke_oslogin_username"

source /tmp/worker/tpu_worker_variables.sh 

export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update -qq
sudo apt-get install gcsfuse -y -qq

sudo mkdir -p /mnt/disks/bucket
sudo chmod -R 777 /mnt/disks/bucket
gcsfuse -o allow_other --file-mode=777 --dir-mode=777 $TPU_GCP_BUCKET /mnt/disks/bucket

sudo groupadd docker
sudo usermod -aG docker $USER

newgrp docker << EONG
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
echo "Running workload..."
/tmp/worker/workload.sh
return_value=$?
echo "Workload finished with return value $return_value"
exit $return_value
EONG
