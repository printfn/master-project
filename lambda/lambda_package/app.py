#!/usr/bin/env python3
import json
import logging
import math
import os
import platform
import shutil
import subprocess
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

PUBLIC_PORT = 80
INTERNAL_PORT = 8001

JAVA_ARGS_1 = [
    "/Library/Java/JavaVirtualMachines/jdk-16.0.2.jdk/Contents/Home/bin/java",
    "--enable-preview",
    "-jar",
    "../l42-controller/out/artifacts/l42_controller_jar/l42-controller.jar",
    str(INTERNAL_PORT)]

JAVA_ARGS_2 = [
    "/opt/L42PortableLinux/L42Internals/jdk-16/bin/java",
    "--enable-preview",
    "-jar",
    "/opt/l42-controller.jar",
    str(INTERNAL_PORT)]

def get_java_args():
    if os.path.exists(JAVA_ARGS_1[0]):
        return JAVA_ARGS_1
    elif os.path.exists(JAVA_ARGS_2[0]):
        return JAVA_ARGS_2
    else:
        raise Exception('could not find java')

def check_health():
    logging.info("Doing health check...")
    req = urllib.request.Request(f"http://localhost:{INTERNAL_PORT}/health")
    try:
        urllib.request.urlopen(req).read()
    except urllib.error.URLError as e:
        return False

    return True

def run_l42_program(request_body):
    if not check_health():
        logging.info("Starting 42 server...")
        subprocess.Popen(
            get_java_args(),
            start_new_session=True
        )
        while not check_health():
            time.sleep(0.5)
        logging.info("Server started")

    req = urllib.request.Request(f"http://localhost:{INTERNAL_PORT}/api")
    req.add_header("Content-Type", "application/json")
    req.data = request_body
    resp = urllib.request.urlopen(req).read()

    return json.loads(resp)

def send_response(server, resp):
    server.send_response(200)
    server.send_header("Content-type", "application/json")
    server.send_header("Access-Control-Allow-Origin", "*")
    server.end_headers()
    server.wfile.write(json.dumps(resp).encode())

class SimpleServer(BaseHTTPRequestHandler):
    def do_GET(self):
        send_response(self, {"ok": True})

    def do_POST(self):
        content_len = int(self.headers.get('Content-Length', 0))
        request_body = self.rfile.read(content_len)
        response = run_l42_program(request_body)
        send_response(self, response)

def get_lambda_request_body(event):
    try:
        body = event['body']
    except:
        raise Exception('failed to read request body')
    if event['isBase64Encoded']:
        body = base64.standard_b64decode(body)

    return body.encode()

def lambda_handler(event, context):
    try:
        request_body = get_lambda_request_body(event)
        result = run_l42_program(request_body)
        statusCode = 200
    except Exception as ex:
        print(ex)
        statusCode = 400
        result = {
            'ok': False,
            'message': str(ex),
        }
    return {
        'statusCode': statusCode,
        'headers': {
            'Access-Control-Allow-Origin': '*',
        },
        'body': json.dumps(result),
    }

if __name__ == "__main__":
    logging.basicConfig(format='[%(asctime)s] %(message)s', level=logging.INFO)

    webServer = HTTPServer(("0.0.0.0", PUBLIC_PORT), SimpleServer)
    logging.info(f"Started server on http://0.0.0.0:{PUBLIC_PORT}")

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    logging.info("Server stopped")
