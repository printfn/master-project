FROM adoptopenjdk/openjdk16:alpine-slim

WORKDIR /opt/app

COPY l42-controller.jar /opt/app
COPY entry_script.sh /opt/app
COPY aws-lambda-rie /usr/local/bin/aws-lambda-rie
ENTRYPOINT [ "/opt/app/entry_script.sh" ]
