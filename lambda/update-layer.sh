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

cp L42PortableLinux.zip lambda_layer.zip

echo >&2 "Deleting large unused files from inside zip file..."
zip -d lambda_layer.zip \
    L42PortableLinux/L42Internals/libjfxwebkit.so \
    L42PortableLinux/L42Internals/jdk-16/lib/src.zip \
    L42PortableLinux/L42Internals/L42.jar \
    L42PortableLinux/L42Internals/L42_lib/\*

echo >&2 "Adding l42-controller.jar..."
zip -j lambda_layer.zip \
    ../l42-controller/out/artifacts/l42_controller_jar/l42-controller.jar

echo >&2 "Successfully created lambda_layer.zip"
