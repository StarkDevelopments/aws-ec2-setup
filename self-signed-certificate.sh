#!/bin/bash
#Author: StarkDevelopments.co.uk
#Environment: AWS EC2 Ubuntu 14.04 x86_64 HVM Linux
#Description: Create self signed certificate.
#AES256 4096bits.

sudo openssl req -newkey rsa:4096 -x509 -sha256 -days 1460 -nodes -out /etc/ssl/certs/server.crt -keyout /etc/ssl/private/server.key

sudo chmod 600 server.crt server.key
sudo chown root:root server.crt server.key

echo Manually edit /etc/apache2/sites-available/default-ssl add key details.
echo SSLCertificateFile /etc/ssl/certs/server.crt
echo SSLCertificateKeyFile /etc/ssl/private/server.key
