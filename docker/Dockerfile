FROM debian:bullseye-slim

WORKDIR /opt/app

COPY l42_package /opt/app
EXPOSE 80
ENTRYPOINT [ "/opt/app/L42PortableLinux/L42Internals/jdk-16/bin/java", "--enable-preview", "-jar", "l42-server.jar", "80" ]
