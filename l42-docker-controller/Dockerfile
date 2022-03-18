# build: docker build --network=host --tag java-docker-rmi .
# run: docker run --publish 80:80 python-docker
# test: curl localhost:80
# get container name: docker ps
# remote: docker exec -u root -it <container name> bash

FROM adoptopenjdk/openjdk16:alpine-jre

WORKDIR /opt/app

RUN mkdir /opt/app
COPY ../rmi-test/out/artifacts/rmi_test_jar/rmi-test.jar /opt/app
CMD ["java", "--enable-preview", "-jar", "/opt/app/rmi-test.jar"]
