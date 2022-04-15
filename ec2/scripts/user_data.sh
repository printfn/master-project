#!/usr/bin/env bash

yum update -y
yum install -y docker
systemctl enable --now docker

aws ecr get-login-password --region ${region} \
    | docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${region}.amazonaws.com/l42
docker pull ${account_id}.dkr.ecr.${region}.amazonaws.com/l42:latest

amazon-linux-extras install -y nginx1
systemctl restart nginx
