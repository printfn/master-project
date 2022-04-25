#!/usr/bin/env bash
set -euo pipefail

# https://ropr2kskcqziasbmulr45x23fm0bujfj.lambda-url.eu-central-1.on.aws

URL="$1"

send() {
    curl -X POST "$URL/execute" \
        --data "{\"files\": {\"This.L42\": \"reuse [L42.is/AdamsTowel]\\nMain=(\\nDebug(S\\\"n = $1\\\")\\n)\"}}"
    echo
}

send 1 &
send 2 &
send 3 &
send 4 &
send 5 &
send 6 &
send 7 &
send 8 &
send 9 &
send 10 &
wait
