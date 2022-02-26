#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f "L42PortableLinux.zip" ]]; then
    echo "Deleting existing L42PortableLinux.zip..."
    rm "L42PortableLinux.zip"
fi

# use the aria2 program if it is installed, which allows for much faster parallel downloading
# install with e.g. `brew install aria2`
if type aria2c &>/dev/null; then
    aria2c -x10 "https://l42.is/L42PortableLinux.zip"
else
    curl -O "https://l42.is/L42PortableLinux.zip"
fi

# delete these two large unused files from inside the zip archive
echo "Deleting large unused files from inside zip file..."
zip -d L42PortableLinux.zip \
    L42PortableLinux/L42Internals/libjfxwebkit.so \
    L42PortableLinux/L42Internals/jdk-16/lib/src.zip
