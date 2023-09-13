#! /bin/bash

sudo docker run --rm -it \
  $TPU_DOCKER_IMAGE \
  /bin/bash -c "echo \"hello world\""
