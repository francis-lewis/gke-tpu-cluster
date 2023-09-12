#! /bin/bash

container_id=$(cat /etc/hostname)
tpu_node_name=gke-tpu-${container_id}
zone=us-central1-a

# This configures OS Login on first run
ssh-keygen -t rsa -f /root/.ssh/google_compute_engine -b 2048
gcloud compute os-login ssh-keys add --key-file=/root/.ssh/google_compute_engine.pub

gke_service_account=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email)
gke_oslogin_username=$(gcloud compute os-login describe-profile | awk '/username/ {print $2}')
echo "gke service account: $gke_service_account"
echo "gke_oslogin_username: $gke_oslogin_username"

echo -e "\ncreating tpu node $tpu_node_name..."
gcloud alpha compute tpus tpu-vm create $tpu_node_name \
  --zone=$zone \
  --accelerator-type=v3-8 \
  --version=tpu-vm-tf-2.7.0 \
  --preemptible \
  --service-account=$gke_service_account \
  --scopes=https://www.googleapis.com/auth/cloud-platform
echo -e "created tpu node $tpu_node_name!"

echo -e "\ncopying tpu_worker.sh to $tpu_node_name..."
gcloud alpha compute tpus tpu-vm scp /scripts/tpu_worker.sh $gke_oslogin_username@$tpu_node_name:/tmp --zone=$zone --quiet
echo -e "copied tpu_worker.sh to $tpu_node_name!"

echo -e "\nrunning tpu_worker.sh on $tpu_node_name..."
gcloud alpha compute tpus tpu-vm ssh $gke_oslogin_username@$tpu_node_name --zone=$zone --quiet -- /tmp/tpu_worker.sh
echo -e "completed tpu_worker.sh on $tpu_node_name!"

echo -e "\ndeleting $tpu_node_name..."
gcloud alpha compute tpus tpu-vm delete $tpu_node_name --zone=$zone --quiet
echo -e "deleted $tpu_node_name!"

gcloud compute os-login ssh-keys remove --key-file=/root/.ssh/google_compute_engine.pub

echo -e "\ngoodbye world"
