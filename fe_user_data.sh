#!/bin/bash -xe

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

sleep 30

dnf update -y

for i in {1..5}; do
  dnf install -y nginx amazon-ssm-agent && break || {
    echo "Retrying dnf install... attempt $i"
    sleep 10
  }
done

systemctl enable nginx
systemctl start nginx

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

systemctl enable nginx
systemctl start nginx

systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

echo "<h1>Hello from the CICD-Deployed Frontend - $(hostname -f)</h1>" > /usr/share/nginx/html/index.html

