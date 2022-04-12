#!/usr/bin/env python3
from flask import Flask, request, Response
import json
import math
import os
import platform
import shutil
import subprocess
import time

app = Flask(__name__)

L42_BINARIES_MAC = "/Applications/L42PortableMac"
L42_BINARIES_LINUX = "/app/L42PortableLinux"
L42_COMMAND_MAC = "L42.command"
L42_COMMAND_LINUX = "L42.sh"

HTTP_OK = 200
L42_FORM_FILE_NAME = "index.html"
DIR_L42_PROJECT = "/tmp/L42_project"
EXAMPLE_CODE = """
reuse [L42.is/AdamsTowel]
Main=(
  Debug(S\"Hello world\")
  )
"""
FILENAME_CODE = "This.L42"
FILENAME_SETTINGS = "Setti.ngs"
LOG_FILE_NAME = "log.txt"
PORT = 80


def log_json(data):
    with open(LOG_FILE_NAME, "a") as json_file:
        json.dump(data, json_file, indent=2)


def log_text(msg):
    with open(LOG_FILE_NAME, "a") as f:
        f.write(msg + "\n")


@app.route("/health", methods=["GET"])
def ping():
    return "<!DOCTYPE html><p>Response from /health: Greetings from L42!</p>"

# allow both GET and POST requests
@app.route("/", methods=["GET", "POST"])
def l42_handler():
    # handle the POST request
    if request.method == "POST":
        input = request.get_json(force=True)
        code = input["code"]
        log_text(code)
        app.logger.info('Code:')
        app.logger.info(code)

        if platform.system() == "Darwin":
            l42_binaries = L42_BINARIES_MAC
            l42_command = L42_COMMAND_MAC
        else:
            l42_binaries = L42_BINARIES_LINUX
            l42_command = L42_COMMAND_LINUX

        result = run_l42_program(l42_binaries, l42_command, code)
        result_json = json.dumps(result)
        app.logger.info('Result:')
        app.logger.info(result_json)

        resp = Response(result_json)
        resp.headers['Access-Control-Allow-Origin'] = '*'
        return resp

    # otherwise handle the GET request
    with open(L42_FORM_FILE_NAME, "r") as f:
        content = f.read()
    return content

@app.route("/urls.js", methods=["GET"])
def url_js_handler():
    with open("urls.js", "r") as f:
        content = f.read()
    return content

def run_l42_program(l42_binaries, l42_command, code):
    if os.path.isdir(DIR_L42_PROJECT):
        shutil.rmtree(DIR_L42_PROJECT)

    os.mkdir(DIR_L42_PROJECT)

    with open(os.path.join(DIR_L42_PROJECT, FILENAME_SETTINGS), "w") as f:
        f.write('maxStackSize = 32M\n')
        f.write('initialMemorySize = 100M\n')
        f.write('maxMemorySize = 256M\n')

    with open(os.path.join(DIR_L42_PROJECT, FILENAME_CODE), "w") as f:
        f.write(code)

    wd = os.getcwd()
    os.chdir(l42_binaries)
    start = time.time()
    result = subprocess.run(
        ["/bin/bash", l42_command, DIR_L42_PROJECT],
        encoding="utf-8",
        capture_output=True
    )
    os.chdir(wd)
    return {
        "ok": True,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "returncode": result.returncode,
        "duration": math.ceil((time.time() - start) * 1000) / 1000
    }


if __name__ == "__main__":
    try:
        app.run(debug=True, host="0.0.0.0", port=PORT)
    except Exception as e:
        log_text(e)
