# Nagios Monitoring Tool

A comprehensive guide to installing and configuring Nagios for server and service monitoring with hands-on examples for monitoring VM01 and its hosted services and applications.

## Table of Contents

- [Overview](#overview)
- [Nagios Installation](#nagios-installation)
- [Monitoring VM01 Server](#monitoring-vm01-server)
- [Monitoring Services](#monitoring-services)
- [Monitoring Applications](#monitoring-applications)
- [Verification and Testing](#verification-and-testing)
- [Troubleshooting](#troubleshooting)

---

## Overview

Nagios is a powerful open-source monitoring and alerting system that helps you:
- Monitor servers and infrastructure
- Track service health and performance
- Monitor running services (Docker, PHP, etc.)
- Monitor hosted applications and websites
- Receive alerts when issues are detected

This guide covers:
1. Installing Nagios server on the monitoring host
2. Adding VM01 as a monitored host
3. Monitoring Docker and PHP8.3 services on VM01
4. Monitoring the mywebsite1.com application hosted on VM01

---

## Nagios Installation

### Prerequisites

- Ubuntu 20.04 LTS / 22.04 LTS or CentOS 7/8
- Root or sudo access
- Minimum 2GB RAM, 2 CPU cores
- 10GB free disk space
- Internet connectivity for package downloads

### Step 1: Update System Packages

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Step 2: Install Required Dependencies

```bash
sudo apt-get install -y \
  wget \
  curl \
  apache2 \
  php \
  php-gd \
  libapache2-mod-php \
  build-essential \
  libgd-dev \
  libmcrypt-dev \
  libssl-dev \
  libpng-dev \
  libjpeg-dev \
  libfreetype6-dev \
  autoconf \
  automake \
  gcc \
  libc6 \
  make \
  unzip \
  git
```

### Step 3: Create Nagios User and Group

```bash
sudo useradd -m -s /bin/bash nagios
sudo groupadd nagcmd
sudo usermod -a -G nagcmd nagios
sudo usermod -a -G nagcmd www-data
```

### Step 4: Download and Extract Nagios Core

```bash
cd /tmp
wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.14/nagios-4.4.14.tar.gz
tar xzf nagios-4.4.14.tar.gz
cd nagios-4.4.14
```

### Step 5: Compile and Install Nagios

```bash
./configure --with-command-group=nagcmd --with-mail=/usr/sbin/sendmail
make all
sudo make install
sudo make install-init
sudo make install-daemonconfig
sudo make install-config
sudo make install-webconf
```

### Step 6: Install Nagios Plugins

```bash
cd /tmp
wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.4.4/nagios-plugins-2.4.4.tar.gz
tar xzf nagios-plugins-2.4.4.tar.gz
cd nagios-plugins-2.4.4
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
sudo make install
```

### Step 7: Install NRPE (Nagios Remote Plugin Executor)

NRPE allows Nagios to execute plugins on remote servers.

```bash
cd /tmp
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.1.2/nrpe-4.1.2.tar.gz
tar xzf nrpe-4.1.2.tar.gz
cd nrpe-4.1.2
./configure --with-nrpe-user=nagios --with-nrpe-group=nagios --with-nagios-user=nagios --with-nagios-group=nagios --enable-command-args
make
sudo make install
sudo make install-daemon-config
sudo make install-daemon
```

### Step 8: Enable Apache Modules

```bash
sudo a2enmod rewrite
sudo a2enmod cgi
sudo systemctl restart apache2
```

### Step 9: Create Nagios Web Admin User

```bash
sudo htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin your_password
```

Replace `your_password` with a secure password.

### Step 10: Start and Enable Nagios Services

```bash
sudo systemctl enable nagios
sudo systemctl enable apache2
sudo systemctl start nagios
sudo systemctl start apache2
```

### Step 11: Verify Installation

Check if Nagios is running:

```bash
sudo systemctl status nagios
```

Access the Nagios web interface:
- URL: `http://your_nagios_server_ip/nagios`
- Username: `nagiosadmin`
- Password: `your_password`

---

## Monitoring VM01 Server

### Step 1: Install NRPE Agent on VM01

SSH into VM01 and follow these steps:

```bash
# Update packages
sudo apt-get update
sudo apt-get upgrade -y

# Install required dependencies
sudo apt-get install -y \
  wget \
  build-essential \
  autoconf \
  automake \
  gcc \
  libssl-dev \
  make \
  unzip

# Create nagios user
sudo useradd -m -s /bin/bash nagios

# Download and install NRPE
cd /tmp
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-4.1.2/nrpe-4.1.2.tar.gz
tar xzf nrpe-4.1.2.tar.gz
cd nrpe-4.1.2

./configure --with-nrpe-user=nagios --with-nrpe-group=nagios --with-nagios-user=nagios --with-nagios-group=nagios --enable-command-args
make
sudo make install-daemon-config
sudo make install-daemon

# Install Nagios plugins on VM01
cd /tmp
wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.4.4/nagios-plugins-2.4.4.tar.gz
tar xzf nagios-plugins-2.4.4.tar.gz
cd nagios-plugins-2.4.4

./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
sudo make install
```

### Step 2: Configure NRPE on VM01

Edit the NRPE configuration file:

```bash
sudo nano /usr/local/nagios/etc/nrpe.cfg
```

Find and modify the following lines:

```bash
# Allow connections from Nagios server
allowed_hosts=127.0.0.1,YOUR_NAGIOS_SERVER_IP

# Enable command arguments
dont_blame_nrpe=1

# Define custom checks for services and applications (see next sections)
```

Save and exit (Ctrl+X, Y, Enter).

### Step 3: Start NRPE Service on VM01

```bash
sudo cp /usr/local/nagios/etc/init.d/nrpe /etc/init.d/nrpe
sudo chmod 755 /etc/init.d/nrpe
sudo systemctl enable nrpe
sudo systemctl start nrpe
```

Verify NRPE is listening:

```bash
sudo netstat -tlnp | grep nrpe
```

You should see NRPE listening on port 5666.

### Step 4: Configure VM01 Host in Nagios Server

On your Nagios server, create a configuration file for VM01:

```bash
sudo nano /usr/local/nagios/etc/objects/vm01.cfg
```

Add the following configuration:

```bash
define host{
    use                     linux-server
    host_name               vm01
    alias                   VM01 Server
    address                 <VM01_IP_ADDRESS>
    check_command           check-host-alive
    max_check_attempts      3
    check_interval          5
    retry_interval          1
    check_period            24x7
    contact_groups          admins
    notification_interval   30
    notification_period     24x7
    notifications_enabled   1
}

# Basic host checks
define service{
    use                     local-service
    host_name               vm01
    service_description     CPU Load
    check_command           check_nrpe!check_load
}

define service{
    use                     local-service
    host_name               vm01
    service_description     Memory Usage
    check_command           check_nrpe!check_memory
}

define service{
    use                     local-service
    host_name               vm01
    service_description     Disk Usage
    check_command           check_nrpe!check_disk
}

define service{
    use                     local-service
    host_name               vm01
    service_description     Uptime
    check_command           check_nrpe!check_uptime
}
```

Replace `<VM01_IP_ADDRESS>` with the actual IP address of VM01.

### Step 5: Verify Configuration and Reload Nagios

```bash
# Verify Nagios configuration syntax
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Reload Nagios to apply changes
sudo systemctl reload nagios
```

---

## Monitoring Services

### Monitoring Docker Service

#### Step 1: Configure NRPE Check for Docker on VM01

On VM01, add the following to `/usr/local/nagios/etc/nrpe.cfg`:

```bash
# Check Docker daemon status
command[check_docker]=/usr/local/nagios/libexec/check_docker.sh
```

#### Step 2: Create Docker Check Script on VM01

Create a custom script to monitor Docker:

```bash
sudo nano /usr/local/nagios/libexec/check_docker.sh
```

Add the following content:

```bash
#!/bin/bash

# Check if Docker daemon is running
if systemctl is-active --quiet docker; then
    echo "Docker service is running"
    exit 0
else
    echo "Docker service is not running"
    exit 2
fi
```

Make the script executable:

```bash
sudo chmod +x /usr/local/nagios/libexec/check_docker.sh
sudo chown nagios:nagios /usr/local/nagios/libexec/check_docker.sh
```

#### Step 3: Configure Docker Service Check in Nagios Server

On the Nagios server, add the following to `/usr/local/nagios/etc/objects/vm01.cfg`:

```bash
# Docker Service Check
define service{
    use                     local-service
    host_name               vm01
    service_description     Docker Service
    check_command           check_nrpe!check_docker
    notifications_enabled   1
}
```

### Monitoring PHP8.3 Service

#### Step 1: Configure NRPE Check for PHP on VM01

On VM01, add the following to `/usr/local/nagios/etc/nrpe.cfg`:

```bash
# Check PHP-FPM service status
command[check_php]=/usr/local/nagios/libexec/check_php.sh
```

#### Step 2: Create PHP Check Script on VM01

Create a custom script to monitor PHP:

```bash
sudo nano /usr/local/nagios/libexec/check_php.sh
```

Add the following content:

```bash
#!/bin/bash

# Check if PHP-FPM is running
if systemctl is-active --quiet php8.3-fpm; then
    # Count active processes
    php_processes=$(ps aux | grep -c '[p]hp-fpm')
    echo "PHP8.3-FPM service is running with $php_processes processes"
    exit 0
else
    echo "PHP8.3-FPM service is not running"
    exit 2
fi
```

Make the script executable:

```bash
sudo chmod +x /usr/local/nagios/libexec/check_php.sh
sudo chown nagios:nagios /usr/local/nagios/libexec/check_php.sh
```

#### Step 3: Configure PHP Service Check in Nagios Server

On the Nagios server, add the following to `/usr/local/nagios/etc/objects/vm01.cfg`:

```bash
# PHP8.3 Service Check
define service{
    use                     local-service
    host_name               vm01
    service_description     PHP8.3-FPM Service
    check_command           check_nrpe!check_php
    notifications_enabled   1
}
```

---

## Monitoring Applications

### Monitoring mywebsite1.com Application

#### Step 1: Configure NRPE Check for the Application on VM01

On VM01, add the following to `/usr/local/nagios/etc/nrpe.cfg`:

```bash
# Check website availability and response time
command[check_website]=/usr/local/nagios/libexec/check_website.sh
```

#### Step 2: Create Website Check Script on VM01

Create a custom script to monitor the website:

```bash
sudo nano /usr/local/nagios/libexec/check_website.sh
```

Add the following content:

```bash
#!/bin/bash

WEBSITE="mywebsite1.com"
TIMEOUT=10
WARNING_TIME=2
CRITICAL_TIME=5

# Check website availability and response time
response_time=$(curl -s -o /dev/null -w '%{time_total}' --connect-timeout $TIMEOUT http://$WEBSITE 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "CRITICAL - Website $WEBSITE is unreachable"
    exit 2
fi

response_time_ms=$(echo "$response_time * 1000" | bc | cut -d. -f1)

if (( $(echo "$response_time > $CRITICAL_TIME" | bc -l) )); then
    echo "CRITICAL - Website $WEBSITE response time: ${response_time}s | response_time=${response_time}s"
    exit 2
elif (( $(echo "$response_time > $WARNING_TIME" | bc -l) )); then
    echo "WARNING - Website $WEBSITE response time: ${response_time}s | response_time=${response_time}s"
    exit 1
else
    echo "OK - Website $WEBSITE is responding in ${response_time}s | response_time=${response_time}s"
    exit 0
fi
```

Make the script executable:

```bash
sudo chmod +x /usr/local/nagios/libexec/check_website.sh
sudo chown nagios:nagios /usr/local/nagios/libexec/check_website.sh
```

#### Step 3: Configure Website Check in Nagios Server

On the Nagios server, add the following to `/usr/local/nagios/etc/objects/vm01.cfg`:

```bash
# Website Application Check
define service{
    use                     local-service
    host_name               vm01
    service_description     mywebsite1.com Application
    check_command           check_nrpe!check_website
    check_interval          3
    retry_interval          1
    notifications_enabled   1
}
```

#### Step 4: Alternative - Direct HTTP Check from Nagios Server

You can also monitor the website directly from the Nagios server without NRPE:

```bash
# Add this to /usr/local/nagios/etc/objects/vm01.cfg
define service{
    use                     local-service
    host_name               vm01
    service_description     mywebsite1.com HTTP Check
    check_command           check_http!-H mywebsite1.com -p 80 -w 2 -c 5
    notifications_enabled   1
}
```

---

## Verification and Testing

### Step 1: Verify Configuration Syntax

On the Nagios server:

```bash
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
```

You should see:

```
Total Warnings: 0
Total Errors: 0
```

### Step 2: Reload Nagios Configuration

```bash
sudo systemctl reload nagios
```

### Step 3: Test NRPE Connection

From the Nagios server, test the connection to VM01:

```bash
/usr/local/nagios/libexec/check_nrpe -H <VM01_IP_ADDRESS>
```

Expected output: `NRPE v4.1.2`

### Step 4: Test Individual Service Checks

```bash
# Test Docker check
/usr/local/nagios/libexec/check_nrpe -H <VM01_IP_ADDRESS> -c check_docker

# Test PHP check
/usr/local/nagios/libexec/check_nrpe -H <VM01_IP_ADDRESS> -c check_php

# Test website check
/usr/local/nagios/libexec/check_nrpe -H <VM01_IP_ADDRESS> -c check_website
```

### Step 5: Access Nagios Web Interface

1. Open your browser and navigate to: `http://your_nagios_server_ip/nagios`
2. Login with your credentials
3. Click on "Hosts" to view VM01
4. Click on "Services" to view all monitored services
5. Verify that all services show as "OK" status

---

## Troubleshooting

### NRPE Connection Issues

**Problem:** Cannot connect to NRPE on VM01

```bash
# Check if NRPE is listening
sudo netstat -tlnp | grep nrpe

# Check NRPE logs
sudo tail -f /var/log/syslog | grep nrpe

# Verify firewall rules
sudo ufw status
sudo ufw allow 5666/tcp
```

### Nagios Configuration Errors

**Problem:** Configuration verification shows errors

```bash
# Check syntax
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# Check specific configuration file
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/objects/vm01.cfg
```

### Service Check Failures

**Problem:** Services show as CRITICAL or UNKNOWN

```bash
# Verify the check command exists
sudo ls -la /usr/local/nagios/libexec/check_*

# Test the check command directly
sudo -u nagios /usr/local/nagios/libexec/check_nrpe -H <VM01_IP> -c check_docker

# Check NRPE command configuration on VM01
sudo grep "command\[check_" /usr/local/nagios/etc/nrpe.cfg
```

### Firewall Issues

**On Nagios Server:**

```bash
sudo ufw allow 5666/tcp
```

**On VM01:**

```bash
sudo ufw allow 5666/tcp from <NAGIOS_SERVER_IP>
```

### Permission Issues

If plugins cannot execute:

```bash
# Fix permissions
sudo chown nagios:nagios /usr/local/nagios/libexec/check_*.sh
sudo chmod 755 /usr/local/nagios/libexec/check_*.sh
```

---

## Summary

You now have:
1. ✅ A fully installed Nagios monitoring server
2. ✅ VM01 added as a monitored host with basic system metrics
3. ✅ Docker service monitoring on VM01
4. ✅ PHP8.3 service monitoring on VM01
5. ✅ mywebsite1.com application monitoring on VM01
6. ✅ Web interface accessible for real-time monitoring
7. ✅ Alert capabilities for critical events

## Additional Resources

- [Nagios Official Documentation](https://www.nagios.org/documentation/)
- [Nagios Plugins](https://nagios-plugins.org/)
- [NRPE Documentation](https://github.com/NagiosEnterprises/nrpe)

---

**Last Updated:** 2026-05-20  
**Author:** Monitoring Tool - Nagios  
**License:** Open Source
