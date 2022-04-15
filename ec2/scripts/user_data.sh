#!/bin/sh

yum update -y
yum install -y docker
systemctl enable --now docker

amazon-linux-extras install -y nginx1
systemctl restart nginx
