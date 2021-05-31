#!/bin/bash
apt update
apt install apache2 -y
echo "Hi!, I am from $(hostname -f)" > /var/www/html/index.html
systemctl apache2 start enable 
a=`sed "s/[^a-zA-Z0-9]//g" <<< $(cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%*()-+' | fold -w 4 | head -n 1)`
sudo hostnamectl set-hostname k8s-node-$a && bash