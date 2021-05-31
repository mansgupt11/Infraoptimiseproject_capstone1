#!/bin/bash
apt update
apt install apache2 -y
apt install python3 -y
apt update -y
apt install software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt install ansible -y
echo "Hi!, I am from $(hostname -f)" > /var/www/html/index.html
systemctl apache2 start enable 
hostnamectl set-hostname k8s-master
