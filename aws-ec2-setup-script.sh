#!/bin/bash
#Author: StarkDevelopments.co.uk
#Environment: AWS EC2 Ubuntu 14.04 x86_64 HVM Linux
#Description: Will configure and install relevant packages to set a newly provisioned instance to be LAMM (Linux, Apache, MySQL, Mono) ready.
#Uses Moo source repo direct from Mono project as Ubuntu package too old.
#Configures various services to confirm to best practice.
#SSL configuration will be rated A+ by SSLabs assuming installation of CA signed certificate.

####################################################
echo Set locale to GB
sudo locale-gen en_GB.UTF-8
echo LANG="en_GB.UTF-8" | sudo tee /etc/default/locale
echo LANGUAGE="en_GB:en" | sudo tee -a /etc/default/locale
####################################################


####################################################
echo Add Mono repo
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/debian wheezy main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list
echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" | sudo tee -a /etc/apt/sources.list.d/mono-xamarin.list
####################################################


####################################################
echo Update repository list
sudo apt-get update
####################################################


####################################################
echo Install required packages
sudo apt-get install -y apache2 apparmor apparmor-utils apparmor-profiles automysqlbackup awscli chkrootkit fail2ban joe libapache2-mod-mono libapache2-mod-security2 logwatch mono-apache-server4 mono-complete mono-devel mono-runtime mono-runtime-common mono-xsp4-base mysql-client mysql-server mysqltuner mytop ntp postfix s3cmd unattended-upgrades unzip
####################################################


####################################################
echo Configure s3cmd
s3cmd --configure
####################################################


####################################################
echo Configure chkrootkit
sudo sed -i 's/^RUN_DAILY=\"false\"/RUN_DAILY=\"true\"/' /etc/chkrootkit.conf
####################################################


####################################################
echo Configure SSHd
echo By using this system, the user consents to such interception, monitoring, | sudo tee /etc/ssh/banner
echo recording, copying, auditing, inspection, and disclosure at the | sudo tee -a /etc/ssh/banner
echo discretion of such personnel or officials.  Unauthorised or improper use | sudo tee -a /etc/ssh/banner
echo of this system may result in civil and criminal penalties and | sudo tee -a /etc/ssh/banner
echo administrative or disciplinary action, as appropriate. By continuing to | sudo tee -a /etc/ssh/banner
echo use this system you indicate your awareness of and consent to these terms | sudo tee -a /etc/ssh/banner
echo and conditions of use. LOG OFF IMMEDIATELY if you do not agree to the | sudo tee -a /etc/ssh/banner
echo conditions stated in this warning. | sudo tee -a /etc/ssh/banner
echo "" | sudo tee -a /etc/ssh/banner

sudo sed -i 's/^#Banner.*/Banner \/etc\/ssh\/banner/' /etc/ssh/sshd_config
sudo sed -i 's/^LoginGraceTime.*/LoginGraceTime 60/' /etc/ssh/sshd_config
####################################################


####################################################
echo Configure Apparmor
sudo apparmor_status
sudo aa-enforce /etc/apparmor.d/*
####################################################


####################################################
echo Add firewall rules
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow mysql
sudo ufw enable
sudo ufw status
####################################################


####################################################
echo Enable Apache modules
sudo a2enmod expires
sudo a2enmod headers
sudo a2enmod mod_mono
sudo a2enmod security2
sudo a2enmod rewrite
sudo a2enmod ssl
####################################################


####################################################
echo Edit Apache config
sudo sed -i 's/^ServerSignature.*/ServerSignature Off/' /etc/apache2/apache2.conf
sudo sed -i 's/^ServerTokens.*/ServerTokens Prod/' /etc/apache2/apache2.conf
sudo sed -i 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks/g' /etc/apache2/apache2.conf

echo ServerSignature Off | sudo tee -a /etc/apache2/apache2.conf
echo ServerTokens Prod | sudo tee -a /etc/apache2/apache2.conf

sudo apache2ctl configtest
sudo service apache2 restart
####################################################


####################################################
echo Edit SSL config
sudo sed -i 's/#SSLCipherSuite.*/SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA/' /etc/apache2/mods-available/ssl.conf
sudo sed -i 's/#SSLHonorCipherOrder.*/SSLHonorCipherOrder on/' /etc/apache2/mods-available/ssl.conf
sudo sed -i 's/SSLProtocol.*/SSLProtocol all -SSLv2 -SSLv3/' /etc/apache2/mods-available/ssl.conf
sudo sed -i 's/SSLCompression.*/SSLCompression off/' /etc/apache2/mods-available/ssl.conf
sudo sed -i 's/SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5.*/#SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5/' /etc/apache2/mods-available/ssl.conf
####################################################


####################################################
echo Configure Fail2Ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo sed -i 's/^destemail.*/destemail = root/' /etc/fail2ban/jail.local
echo Manually set enabled = true for [ssh], [apache], [apache-noscript], [apache-overflows], [postfix]
####################################################


####################################################
echo Setup hosts.allow
echo ALL: 84.39.117.57 | sudo tee -a /etc/hosts.allow
echo ALL: 84.39.116.180 | sudo tee -a /etc/hosts.allow
####################################################


####################################################
echo Configure Logwatch
sudo cp /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/
sudo cp /usr/share/logwatch/default.conf/logfiles/http.conf /etc/logwatch/conf/logfiles/
sudo mkdir /var/cache/logwatch

sudo sed -i 's/^Detail.*/Detail = High/' /etc/logwatch/conf/logwatch.conf
sudo sed -i 's/^Output = stdout/Output = mail/' /etc/logwatch/conf/logwatch.conf

echo LogFile = apache2/*combined.log | sudo tee -a /etc/logwatch/conf/logfiles/http.conf
####################################################


####################################################
echo Configure Modsecurity
#Conf is found here /etc/apache2/mods-available/security2.conf and references the *conf in the modsecurity folder
sudo sed -i 's/^SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf-recommended 
####################################################


####################################################
echo Allow OS to fsck on reboot
echo FSCKFIX=yes | sudo tee -a /etc/default/rcS
####################################################


####################################################
echo Configure Mono->.NET version
echo Include /etc/mono-server4/mono-server4-hosts.conf | sudo tee -a /etc/apache2/mods-available/mod_mono.conf
####################################################


####################################################
echo Import AWS email certificates for emailing via mono.
sudo certmgr -ssl -m smtps://email-smtp.eu-west-1.amazonaws.com:465
sudo mozroots --import --sync --machine
####################################################


####################################################
echo Configure .NET machine.config
echo set <deployment retail="true" /> in /etc/mono/4.0/machine.config
echo set <deployment retail="true" /> in /etc/mono/4.5/machine.config
####################################################


####################################################
echo Configure Postfix
echo Choose internet when prompted at postfix install.
echo postmaster: nobody@nowhere.co.uk | sudo tee /etc/aliases
echo root: nobody@nowhere.co.uk | sudo tee -a /etc/aliases
echo ubuntu: nobody@nowhere.co.uk | sudo tee -a /etc/aliases

sudo newaliases
####################################################


####################################################
echo Upgrade packages and OS.
sudo apt-get upgrade && sudo apt-get dist-upgrade

echo Run sudo reboot
echo Run sudo apt-get autoremove
####################################################

