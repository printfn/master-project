clean:
	docker system prune -a -f

build: clean
	cp -f ../l42-controller/out/artifacts/l42_controller_jar/l42-controller.jar .
	docker build --network=host --tag l42-docker-controller .

run:
	docker run --publish 9000:8080 -it l42-docker-controller rie

.PHONY: build clean run
