#! /bin/bash

source /scripts/launcher/tpu_launcher_variables.sh

container_id=$(cat /etc/hostname)
tpu_node_name=${TPU_VM_PREFIX}-${container_id}

# This configures OS Login on first run
ssh-keygen -t rsa -f /root/.ssh/google_compute_engine -b 2048
gcloud compute os-login ssh-keys add --key-file=/root/.ssh/google_compute_engine.pub

gke_service_account=$(curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email)
gke_oslogin_username=$(gcloud compute os-login describe-profile | awk '/username/ {print $2}')
echo "gke service account: $gke_service_account"
echo "gke_oslogin_username: $gke_oslogin_username"

echo -e "\ncreating tpu node $tpu_node_name..."
gcloud alpha compute tpus tpu-vm create $tpu_node_name \
  --zone=$TPU_VM_ZONE \
  --accelerator-type=$TPU_VM_ACCELERATOR_TYPE \
  --version=$TPU_VM_VERSION \
  --preemptible \
  --service-account=$gke_service_account \
  --scopes=https://www.googleapis.com/auth/cloud-platform
if [[ $? -ne 0 ]]; then
  echo "couldn't create $tpu_node_name!"; exit 1
fi
echo -e "created tpu node $tpu_node_name!"

echo -e "\ncopying tpu_worker.sh to $tpu_node_name..."
gcloud alpha compute tpus tpu-vm scp /scripts/worker $gke_oslogin_username@$tpu_node_name:/tmp --zone=$TPU_VM_ZONE --recurse --quiet
echo -e "copied /scripts/worker to $tpu_node_name!"

echo -e "\nrunning tpu_worker.sh on $tpu_node_name..."
gcloud alpha compute tpus tpu-vm ssh $gke_oslogin_username@$tpu_node_name --zone=$TPU_VM_ZONE --quiet -- /tmp/worker/tpu_worker.sh
return_status=$?
echo -e "completed tpu_worker.sh on $tpu_node_name!"

echo -e "\ndeleting $tpu_node_name..."
gcloud alpha compute tpus tpu-vm delete $tpu_node_name --zone=$TPU_VM_ZONE --quiet
echo -e "deleted $tpu_node_name!"

gcloud compute os-login ssh-keys remove --key-file=/root/.ssh/google_compute_engine.pub

echo -e "\ngoodbye world"
exit $return_status
