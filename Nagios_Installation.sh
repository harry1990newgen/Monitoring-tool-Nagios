root@vm01:/home/# cat nagios-installation.sh 
#!/bin/bash

# Nagios Core Installation Script for Ubuntu 24.04
# Run as root or with sudo

set -e

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing dependencies..."
apt install -y \
  apache2 \
  php \
  gcc \
  make \
  unzip \
  wget \
  curl \
  build-essential \
  libgd-dev \
  openssl \
  libssl-dev \
  apache2-utils \
  daemon \
  libapache2-mod-php \
  pkg-config \
  autoconf \
  gettext \
  automake \
  snmp \
  libnet-snmp-perl

cd /tmp

echo "Downloading Nagios Core..."
wget -O nagioscore.tar.gz https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.9.tar.gz

tar xzf nagioscore.tar.gz
cd nagios-4.5.9

echo "Creating nagios user and group..."
useradd nagios || true
groupadd nagcmd || true
usermod -a -G nagcmd nagios
usermod -a -G nagcmd www-data

echo "Configuring Nagios..."
./configure --with-command-group=nagcmd

echo "Compiling Nagios..."
make all

echo "Installing Nagios..."
make install
make install-init
make install-config
make install-commandmode
make install-webconf

echo "Setting up Apache..."
a2enmod rewrite
a2enmod cgi

echo "Creating Nagios web admin user..."
htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin StrongPassword123

echo "Downloading Nagios Plugins..."
cd /tmp
wget https://nagios-plugins.org/download/nagios-plugins-2.4.12.tar.gz

tar zxf nagios-plugins-2.4.12.tar.gz
cd nagios-plugins-2.4.12

echo "Installing plugins..."
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install

echo "Starting services..."
systemctl restart apache2

systemctl enable apache2
systemctl enable nagios

systemctl start nagios

echo "Allowing HTTP through firewall..."
ufw allow Apache || true

echo "=================================================="
echo "Nagios installation completed!"
echo "Access URL: http://YOUR_SERVER_IP/nagios"
echo "Username: nagiosadmin"
echo "Password: StrongPassword123"
echo "=================================================="

root@vm01:/home/harry# 
