# Running L42 as Docker container

## Commands

### Build

```bash
docker system prune -a -f
cp -f ../l42-controller/out/artifacts/l42_controller_jar/l42-controller.jar .
docker build --network=host --tag l42-docker-controller .
```

### Run with built-in web server on port 80

```bash
docker run --publish 80:80 -it l42-docker-controller
```

### Run with Lambda Runtime Interface Emulator

```bash
docker run --publish 9000:8080 -it l42-docker-controller rie
```

The function can then be invoked with:

```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
```

### Debug

```bash
docker run --publish 80:80 -v "$(pwd)/../l42-examples:/opt/app/examples" -it l42-docker-controller /bin/sh
```

### Upload to AWS ECR

```bash
# put the following lines into ~/L42_exports.sh
#   export AWS_PROFILE=...
#   export region=...
#   export account=...
source ~/L42_exports.sh

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $account.dkr.ecr.$region.amazonaws.com/l42-docker-controller
aws ecr create-repository --region $region --repository-name l42-docker-controller
aws ecr batch-delete-image --region $region --repository-name l42-docker-controller --image-ids imageTag=latest
docker tag l42-docker-controller:latest $account.dkr.ecr.$region.amazonaws.com/l42-docker-controller:latest
docker push $account.dkr.ecr.$region.amazonaws.com/l42-docker-controller:latest
aws ecr list-images --region $region --repository-name l42-docker-controller
```

### References:

* <https://github.com/aws/aws-lambda-java-libs/tree/master/aws-lambda-java-runtime-interface-client>
* <https://docs.aws.amazon.com/lambda/latest/dg/images-test.html#images-test-alternative>
* <https://docs.aws.amazon.com/lambda/latest/dg/java-package.html>
