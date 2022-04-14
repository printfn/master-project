#!/usr/bin/env bash
set -euxo pipefail
cd "$(dirname "$0")"

# put the following lines into ~/L42_exports.sh
#   export AWS_PROFILE=...
#   export region=...
#   export account=...
source ~/L42_exports.sh

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $account.dkr.ecr.$region.amazonaws.com/l42
aws ecr create-repository --region $region --repository-name l42 || true
aws ecr batch-delete-image --region $region --repository-name l42 --image-ids imageTag=latest
docker tag l42:latest $account.dkr.ecr.$region.amazonaws.com/l42:latest
docker push $account.dkr.ecr.$region.amazonaws.com/l42:latest
aws ecr list-images --region $region --repository-name l42
