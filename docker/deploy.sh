#!/usr/bin/env bash
set -euxo pipefail

# put the following lines into ~/L42_exports.sh
#   export AWS_PROFILE=...
#   export region=...
#   export account=...
source ~/L42_exports.sh

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $account.dkr.ecr.$region.amazonaws.com/l42-docker-controller
aws ecr create-repository --region $region --repository-name l42-docker-controller || true
aws ecr batch-delete-image --region $region --repository-name l42-docker-controller --image-ids imageTag=latest
docker tag l42-docker-controller:latest $account.dkr.ecr.$region.amazonaws.com/l42-docker-controller:latest
docker push $account.dkr.ecr.$region.amazonaws.com/l42-docker-controller:latest
aws ecr list-images --region $region --repository-name l42-docker-controller
