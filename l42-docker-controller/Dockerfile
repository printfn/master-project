FROM adoptopenjdk/openjdk16:alpine-slim

WORKDIR /opt/app

COPY l42-controller.jar /opt/app
CMD ["java", "--enable-preview", "-jar", "/opt/app/l42-controller.jar", "80"]
