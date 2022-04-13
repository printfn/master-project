#!/usr/bin/env python3
from flask import Flask, request, Response
import json
import math
import os
import platform
import shutil
import subprocess
import time
import urllib.request

app = Flask(__name__)

PUBLIC_PORT = 80
INTERNAL_PORT = 8001

@app.route("/health", methods=["GET"])
def ping():
    return "<!DOCTYPE html><p>Response from /health: Greetings from L42!</p>"

@app.route("/", methods=["POST"])
def l42_handler():
    input = request.get_json(force=True)
    code = input["code"]
    app.logger.info('Code:')
    app.logger.info(code)

    result = run_l42_program(code)
    result_json = json.dumps(result)
    app.logger.info('Result:')
    app.logger.info(result_json)

    resp = Response(result_json)
    resp.headers['Access-Control-Allow-Origin'] = '*'
    return resp

def check_health():
    app.logger.info("Doing health check...")
    req = urllib.request.Request(f"http://localhost:{INTERNAL_PORT}/health")
    try:
        urllib.request.urlopen(req).read()
    except urllib.error.URLError as e:
        return False

    return True

JAVA_ARGS = [
    "/Library/Java/JavaVirtualMachines/jdk-16.0.2.jdk/Contents/Home/bin/java",
    "--enable-preview",
    "-jar",
    "../l42-controller/out/artifacts/l42_controller_jar/l42-controller.jar",
    str(INTERNAL_PORT)]

def run_l42_program(code):
    if not check_health():
        app.logger.info("Starting 42 server...")
        subprocess.Popen(
            JAVA_ARGS,
            start_new_session=True
        )
        while not check_health():
            time.sleep(0.5)
        app.logger.info("Server started")

    req = urllib.request.Request(f"http://localhost:{INTERNAL_PORT}/api")
    req.add_header("Content-Type", "application/json")
    req.data = json.dumps({ "code": code }).encode()
    resp = urllib.request.urlopen(req).read()

    return json.loads(resp)

if __name__ == "__main__":
    try:
        app.run(debug=True, host="0.0.0.0", port=PUBLIC_PORT)
    except Exception as e:
        app.logger.error(e)
