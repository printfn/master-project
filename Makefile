clean:
	docker system prune -a -f
	rm -rf artifacts
	rm -rf l42-server/out l42-server/target
	rm -rf ~/.m2

build:
	./scripts/update-package.sh

	# docker
	rm -rf artifacts/docker_image
	mkdir artifacts/docker_image
	unzip -u artifacts/l42_package.zip -d artifacts/docker_image/l42_package/
	cp docker/Dockerfile artifacts/docker_image/
	docker build --network=host --tag l42 artifacts/docker_image

run:
	docker run --publish 8000:80 -it l42

ecr:
	./scripts/deploy-ecr.sh

docker_debug:
	docker run --entrypoint /bin/sh -it l42

logs:
	aws --region eu-central-1 logs tail /aws/lambda/L42 --follow

.PHONY: build clean deploy logs run
