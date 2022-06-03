clean:
	docker system prune -a -f
	rm -rf artifacts
	rm -rf l42-server/out l42-server/target
	rm -rf ~/.m2

mild_clean:
	rm -rf artifacts/docker_image artifacts/L42PortableLinux artifacts/bootstrap
	rm -rf artifacts/l42-pom.xml artifacts/l42-server.jar artifacts/l42_package.zip
	rm -rf l42-server/out l42-server/target

zip:
	./scripts/update-package.sh

docker: zip
	rm -rf artifacts/docker_image
	mkdir artifacts/docker_image
	unzip -u artifacts/l42_package.zip -d artifacts/docker_image/l42_package/
	cp docker/Dockerfile artifacts/docker_image/
	docker build --network=host --tag l42 artifacts/docker_image

safeNativeCode:
	mkdir -p artifacts
	rm -rf artifacts/safe-native-code
	git clone git@github.com:sanjay900/safe-native-code.git artifacts/safe-native-code
	(cd artifacts/safe-native-code && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_261.jdk/Contents/Home ./gradlew jar)

build: zip docker

run:
	docker run --publish 8000:80 -it l42

ecr:
	./scripts/deploy-ecr.sh

docker_debug:
	docker run --entrypoint /bin/sh -it l42

docker_run:
	docker run l42

logs:
	aws --region ap-southeast-2 logs tail /aws/lambda/L42 --follow

.PHONY: build clean deploy logs run safeNativeCode
