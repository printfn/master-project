#!/usr/bin/env bash
set -euxo pipefail
cd "$(dirname "$0")"

# put the following lines into L42_exports.sh in the root of this project
#   export AWS_PROFILE=...
#   export region=...
source ../L42_exports.sh

account="$(aws sts get-caller-identity | jq -r .Account)"

aws ecr get-login-password --region $region \
    | docker login --username AWS --password-stdin $account.dkr.ecr.$region.amazonaws.com/l42

if ! aws ecr describe-repositories --region $region --repository-names l42 2>/dev/null; then
    aws ecr create-repository --region $region --repository-name l42
fi

aws ecr batch-delete-image --region $region --repository-name l42 --image-ids imageTag=latest
docker tag l42:latest $account.dkr.ecr.$region.amazonaws.com/l42:latest
docker push $account.dkr.ecr.$region.amazonaws.com/l42:latest
aws ecr list-images --region $region --repository-name l42
