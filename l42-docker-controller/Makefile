clean:
	docker system prune -a -f

build: clean
	cp -f ../l42-controller/out/artifacts/l42_controller_jar/l42-controller.jar .
	docker build --network=host --tag l42-docker-controller .

run:
	docker run --publish 9000:8080 -it l42-docker-controller rie

deploy:
	./deploy.sh

logs:
	aws --region ap-southeast-2 logs tail /aws/lambda/L42 --follow

.PHONY: build clean deploy logs run
