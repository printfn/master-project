#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f "L42PortableLinux.zip" ]]; then
    echo >&2 "Using existing L42PortableLinux.zip"
else
    echo >&2 "Downloading L42PortableLinux.zip..."
    # use the aria2 program if it is installed, which allows for much faster parallel downloading
    # install with e.g. `brew install aria2`
    if type aria2c &>/dev/null; then
        aria2c -x10 "https://l42.is/L42PortableLinux.zip"
    else
        curl -O "https://l42.is/L42PortableLinux.zip"
    fi
    echo >&2 "... successfully downloaded L42PortableLinux.zip"
fi

cp L42PortableLinux.zip l42_package.zip

echo >&2 "Deleting large unused files from inside zip file..."
zip -d l42_package.zip \
    L42PortableLinux/L42Internals/libjfxwebkit.so \
    L42PortableLinux/L42Internals/jdk-16/lib/src.zip \
    L42PortableLinux/L42Internals/L42.jar \
    L42PortableLinux/L42Internals/L42_lib/\*

echo >&2 "Adding l42-controller.jar..."
zip -j l42_package.zip \
    ../l42-controller/out/artifacts/l42_controller_jar/l42-controller.jar

echo >&2 "Adding bootstrap..."
BOOTSTRAP="#!/bin/sh
cd \$LAMBDA_TASK_ROOT
/var/task/L42PortableLinux/L42Internals/jdk-16/bin/java \\
    --enable-preview \\
    --add-opens java.base/java.util=ALL-UNNAMED \\
    -cp /var/task/l42-controller.jar \\
    com.amazonaws.services.lambda.runtime.api.client.AWSLambda \\
    l42client.Lambda"
TEMP_DIR="$(mktemp -d)"
echo "$BOOTSTRAP" >"$TEMP_DIR/bootstrap"
chmod u+x "$TEMP_DIR/bootstrap"
zip -j l42_package.zip \
    "$TEMP_DIR/bootstrap"
rm -rf "$TEMP_DIR"

echo >&2 "Successfully created l42_package.zip"
