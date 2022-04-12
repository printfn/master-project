# Running L42 server as Docker container

Details for the L42 project can be found [here](https://L42.is/download.xhtml)

## Commands

### Build server

```bash
curl -O https://L42.is/L42PortableLinux.zip
unzip L42PortableLinux.zip
rm -f L42PortableLinux.zip

# put the following lines into ~/L42_exports.sh
#   export AWS_PROFILE=...
#   export region=...
#   export account=...
source ~/L42_exports.sh

docker system prune -a -f
docker build --network=host --tag l42 .
docker images --filter reference=l42

aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $account.dkr.ecr.$region.amazonaws.com/l42
aws ecr create-repository --region $region --repository-name l42
aws ecr batch-delete-image --region $region --repository-name l42 --image-ids imageTag=latest
docker tag l42:latest $account.dkr.ecr.$region.amazonaws.com/l42:latest
docker push $account.dkr.ecr.$region.amazonaws.com/l42:latest
aws ecr list-images --region $region --repository-name l42
```

### Start server locally

```bash
docker run --publish 80:80 l42
```

### Start client

Open index.html in browser (in index.html uncomment the line // const L42_SERVER = 'http://localhost';)
