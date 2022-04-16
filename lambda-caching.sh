#!/usr/bin/env bash

LAMBDA_URL=https://ropr2kskcqziasbmulr45x23fm0bujfj.lambda-url.eu-central-1.on.aws
CODE='{"code":"reuse [L42.is/AdamsTowel]\nMain=(\n  Debug(S\"Hello world from 42\")\n  )"}'
MAX_SECONDS=900

while :; do
    echo "Calling Lambda at $(date)..."
    echo "Calling lambda at $(date)..." >>log.txt
    OUTPUT="$(curl -s -X POST "$LAMBDA_URL" --data-raw "$CODE")"
    echo "$OUTPUT"
    echo "$OUTPUT" >>log.txt
    echo "Done calling lambda at $(date)"
    echo "Done calling lambda at $(date)" >>log.txt
    SLEEP_TIME="$(node -e "console.log(Math.floor($RANDOM/32767*$MAX_SECONDS))")"
    echo "Sleeping for $SLEEP_TIME seconds..."
    echo "Sleeping for $SLEEP_TIME seconds..." >>log.txt
    sleep "$SLEEP_TIME"
    echo -e "Finished sleeping\n\n\n\n"
    echo -e "Finished sleeping\n\n\n\n" >>log.txt
done
