#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# This script creates a `l42_package.zip` file that can be uploaded to
# AWS Lambda to be executed, or its contents can be extracted into a
# Docker image.

mkdir -p artifacts

if [[ -f "artifacts/L42PortableLinux.zip" ]]; then
    echo >&2 "Using existing artifacts/L42PortableLinux.zip"
else
    echo >&2 "Downloading artifacts/L42PortableLinux.zip..."
    # use the aria2 program if it is installed, which allows for much faster parallel downloading
    # install with e.g. `brew install aria2`
    if type aria2c &>/dev/null; then
        aria2c -x10 -d artifacts "https://l42.is/L42PortableLinux.zip"
    else
        curl -o artifacts/L42PortableLinux.zip "https://l42.is/L42PortableLinux.zip"
    fi
    echo >&2 "... successfully downloaded artifacts/L42PortableLinux.zip"
fi

cp artifacts/L42PortableLinux.zip artifacts/l42_package.zip

echo >&2 "Deleting large unused files from inside zip file..."
zip -d artifacts/l42_package.zip \
    L42PortableLinux/L42Internals/libjfxwebkit.so \
    L42PortableLinux/L42Internals/jdk-16/lib/src.zip \
    L42PortableLinux/L42Internals/L42.jar \
    L42PortableLinux/L42Internals/L42_lib/\*

echo >&2 "Adding l42-server.jar..."
zip --junk-paths artifacts/l42_package.zip \
    l42-server/out/artifacts/l42_server_jar/l42-server.jar

echo >&2 "Adding bootstrap..."
BOOTSTRAP="#!/bin/sh
cd \$LAMBDA_TASK_ROOT
/var/task/L42PortableLinux/L42Internals/jdk-16/bin/java \\
    --enable-preview \\
    --add-opens java.base/java.util=ALL-UNNAMED \\
    -cp /var/task/l42-server.jar \\
    com.amazonaws.services.lambda.runtime.api.client.AWSLambda \\
    l42server.Lambda"
echo "$BOOTSTRAP" >"artifacts/bootstrap"
chmod u+x "artifacts/bootstrap"
zip --junk-paths artifacts/l42_package.zip \
    "artifacts/bootstrap"

echo >&2 "Successfully created artifacts/l42_package.zip"
