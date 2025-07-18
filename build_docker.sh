#! /bin/bash
compute_cap=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | tr -d '.')
echo $compute_cap

docker buildx build -f "./Dockerfile" --tag "cuda_homeserver" --label "cuda_homeserver-dev" . --build-arg COMPUTE_CAP=$compute_cap

docker run -d -it --runtime=nvidia --gpus all -p 2222:22 --name "cuda_homeserver" cuda_homeserver:latest 
