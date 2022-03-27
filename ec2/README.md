Push and tag latest image:

```bash
docker tag l42-docker-controller printfn/l42
docker push printfn/l42
```

Start an EC2 instance:
  * Type: t2.small (1 vCPU, 2 GB memory)
  * Security Group: open ports 22, 80 and 443

On the EC2 instance:

```bash
sudo yum update
sudo yum install -y docker
sudo systemctl enable --now docker
sudo docker pull printfn/l42

sudo amazon-linux-extras install -y nginx1

# Disable the HTTP server, enable the HTTPS server
# Set server_name to "aws.flry.net"
# Add:
#     location / {
#         proxy_pass http://localhost:80;
#     }
# Remove:
#     ssl_ciphers line
sudo vim /etc/nginx/nginx.conf

sudo mkdir -p /etc/pki/nginx/private
sudo vim /etc/pki/nginx/server.crt
sudo vim /etc/pki/nginx/private/server.key

sudo docker run --publish 80:80 -it printfn/l42
```
