#!/bin/bash -xe

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

sleep 30

dnf update -y

dnf install -y amazon-ssm-agent python3 git

systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

echo "Hello from the Backend - $(hostname -f)" > /var/www/html/index.html
dnf install -y httpd
systemctl enable httpd
systemctl start httpd

