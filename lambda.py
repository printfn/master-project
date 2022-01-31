#!/usr/bin/env python3
import base64
import json
import os
import shutil
import subprocess

HELLO_WORLD = """
reuse [L42.is/AdamsTowel]
Main=(
  Debug(S"Hello world from 42")
  )
"""

def run_l42_program(code):
    if os.path.isdir('/tmp/L42Project'):
        shutil.rmtree('/tmp/L42Project')
    
    os.mkdir('/tmp/L42Project')
    
    with open('/tmp/L42Project/Setti.ngs', 'x') as f:
        #f.write('maxStackSize = 32M\n')
        #f.write('initialMemorySize = 100M\n')
        #f.write('maxMemorySize = 256M\n')
        pass
        
    with open('/tmp/L42Project/This.L42', 'x') as f:
        f.write(code)
    
    wd = os.getcwd()
    os.chdir("/opt/L42PortableLinux")
    result = subprocess.run(
        ["/bin/sh", "L42.sh", "/tmp/L42Project"],
        encoding='utf-8',
        capture_output=True)
    os.chdir(wd)
    return {
        'stdout': result.stdout,
        'stderr': result.stderr,
    }

def get_body_obj(event):
    body = event['body']
    if event['isBase64Encoded']:
        body = base64.standard_b64decode(body)
    return json.loads(body)

def lambda_handler(event, context):
    code = HELLO_WORLD
    try:
        code = get_body_obj(event)['code']
    except Exception as err:
        print(err)
        pass
    result = run_l42_program(code)
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }

def list_files(startpath):
    print('Listing files in {}:'.format(startpath))
    for root, dirs, files in os.walk(startpath):
        level = root.replace(startpath, '').count(os.sep)
        indent = ' ' * (4 * level)
        print('{}{}/'.format(indent, os.path.basename(root)))
        subindent = ' ' * 4 * (level + 1)
        for f in files:
            print('{}{}'.format(subindent, f))
