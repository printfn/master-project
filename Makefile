clean:
	docker system prune -a -f
	rm -rf docker/l42_package

build: clean
	./lambda/update-layer.sh
	unzip -u lambda/l42_package.zip -d docker/l42_package/
	docker build --network=host --tag l42 docker

run:
	docker run --publish 8000:80 -it l42

ecr:
	./docker/deploy-ecr.sh

docker_debug:
	docker run --entrypoint /bin/sh -it l42

logs:
	aws --region eu-central-1 logs tail /aws/lambda/L42 --follow

.PHONY: build clean deploy logs run
