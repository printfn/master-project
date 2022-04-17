#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

LAMBDA_URL=https://ropr2kskcqziasbmulr45x23fm0bujfj.lambda-url.eu-central-1.on.aws
CODE='{"code":"reuse [L42.is/AdamsTowel]\nMain=(\n  Debug(S\"Hello world from 42\")\n  )"}'
MAX_SECONDS=900

while :; do
    echo "Calling Lambda at $(date)..."
    echo "Calling lambda at $(date)..." >>../artifacts/log.txt
    OUTPUT="$(curl -s -X POST "$LAMBDA_URL" --data-raw "$CODE")"
    echo "$OUTPUT"
    echo "$OUTPUT" >>../artifacts/log.txt
    echo "Done calling lambda at $(date)"
    echo "Done calling lambda at $(date)" >>../artifacts/log.txt
    SLEEP_TIME="$(node -e "console.log(Math.floor($RANDOM/32767*$MAX_SECONDS))")"
    echo "Sleeping for $SLEEP_TIME seconds..."
    echo "Sleeping for $SLEEP_TIME seconds..." >>../artifacts/log.txt
    sleep "$SLEEP_TIME"
    echo -e "Finished sleeping\n\n\n\n"
    echo -e "Finished sleeping\n\n\n\n" >>../artifacts/log.txt
done
