#!/bin/sh

JAVA_PATH="/Library/Java/JavaVirtualMachines/jdk-16.0.2.jdk/Contents/Home/bin/java"
if [ ! -f "$JAVA_PATH" ]; then
    JAVA_PATH="java"
fi

L42_JAR_PATH="/opt/app/l42-controller.jar"
if [ ! -f "$L42_JAR_PATH" ]; then
    L42_JAR_PATH="l42-controller.jar"
fi

if [ ! -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
    echo "Launched inside a Lambda environment: running the lambda function"

    # the --add-opens options is necessary for Java 16, see
    # https://github.com/aws/aws-lambda-java-libs/issues/261 for more info

    exec $JAVA_PATH \
        "--enable-preview" \
        "--add-opens" java.base/java.util=ALL-UNNAMED \
        "-cp" "$L42_JAR_PATH" \
        com.amazonaws.services.lambda.runtime.api.client.AWSLambda \
        l42client.Lambda
elif [ "$#" -gt 0 ] && [ "$1" = "rie" ]; then
    echo "Launched with the \"rie\" option:"
    echo "   Launching the AWS Lambda Runtime Interface Emulator"
    echo "You can invoke the function with:"
    echo "curl -X POST \"http://localhost:9000/2015-03-31/functions/function/invocations\" -d '{}'"
    exec /usr/local/bin/aws-lambda-rie "$0"
else
    echo "Starting a server on port 80"
    exec $JAVA_PATH \
        "--enable-preview" \
        "-jar" "$L42_JAR_PATH" 80
fi
