# Ubuntu Odoo Automated Installer

One-command installation of Ubuntu Server + Secured Odoo with custom ports, firewall, and automatic security hardening.

![Version](https://img.shields.io/badge/version-2.4-blue.svg)
![Odoo](https://img.shields.io/badge/Odoo-14.0--19.0-green.svg)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-orange.svg)
![License](https://img.shields.io/badge/license-MIT-yellow.svg)

## Table of Contents
- [Quick Start](#quick-start)
- [What It Does](#what-it-does)
- [System Requirements](#system-requirements)
- [Installation Options](#installation-options)
- [Interactive Configuration](#interactive-configuration)
- [Default Configuration](#default-configuration)
- [Access URLs](#access-urls)
- [Post-Installation Structure](#post-installation-structure)
- [Security Features](#security-features)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [FAQ](#faq)

## Quick Start

Download and run the installation script in one command:

```bash
wget -O install.sh https://raw.githubusercontent.com/eisax/odomento/main/install-ubuntu-odoo.sh
chmod +x install.sh
sudo ./install.sh
```

The script will guide you through interactive configuration and automatically install and secure everything.

## What It Does

This script automates the complete installation and optimization of:

- **Ubuntu Server 22.04 LTS** - Optimized and hardened security settings.
- **Odoo** - Support for versions 14.0, 15.0, 16.0, 17.0, 18.0, or 19.0.
- **PostgreSQL** - Relational database configured with a custom port.
- **Nginx** - Reverse proxy featuring custom domain support.
- **Firewall (UFW)** - Restricted incoming access with custom ports.
- **Fail2Ban** - Intrusion prevention blocking brute-force attempts.
- **Automatic Backups** - Daily backups for database and file attachment stores.
- **Webmin (Optional)** - Web-based control panel for server management.
- **SSH Security** - Enforces custom port and key-based authentication.

## System Requirements

| Component | Minimum | Recommended |
| :--- | :--- | :--- |
| **OS** | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4 GB | 8+ GB |
| **Disk** | 20 GB SSD | 50+ GB SSD |
| **Network** | Static IP | Static IP + Domain |

## Installation Options

### Option 1: Direct Download (Recommended)
```bash
wget https://raw.githubusercontent.com/eisax/odomento/main/install-ubuntu-odoo.sh
chmod +x install-ubuntu-odoo.sh
sudo ./install-ubuntu-odoo.sh
```

### Option 2: Clone Repository
```bash
git clone https://github.com/eisax/odomento.git
cd odomento
chmod +x install-ubuntu-odoo.sh
sudo ./install-ubuntu-odoo.sh
```

### Option 3: One-Liner (Fastest)
```bash
curl -sSL https://raw.githubusercontent.com/eisax/odomento/main/install-ubuntu-odoo.sh | sudo bash
```

## Interactive Configuration

During installation, you will be prompted to configure:

### 1. Domain Name
```text
Domain name (e.g., erp.mycompany.com) [systemerp.local]: 
```
> **Tip:** Use your actual domain for production. For testing, use the default.

### 2. Port Configuration
```text
SSH Port [8173]: 
Odoo Port [9017]: 
PostgreSQL Port [6792]: 
```
> **Security Note:** Running on non-standard ports significantly reduces automated brute-force attacks.

### 3. Webmin (Optional)
```text
Install Webmin? (y/N): 
Webmin Port [12579]: 
```
> **Note:** Webmin provides a web-based administration dashboard. Recommended for users new to CLI management.

### 4. Odoo Version
```text
Odoo Version [17.0]: 
Available: 14.0, 15.0, 16.0, 17.0, 18.0, 19.0
```

### 5. Network Configuration
```text
Server IP address [192.168.1.100]: 
Gateway [192.168.1.1]: 
```
> The script auto-detects these network parameters. Press `Enter` to accept the detected settings.

### 6. Passwords
```text
PostgreSQL password (postgres): 
PostgreSQL password (sys-erp): 
Odoo Master Password: 
```

## Default Configuration

If you press `Enter` to accept all configuration prompts, the following settings will be applied:

| Component | Default Value |
| :--- | :--- |
| **Domain** | `systemerp.local` |
| **SSH Port** | `8173` |
| **Odoo Port** | `9017` |
| **Odoo Longpolling** | `10017` |
| **PostgreSQL Port** | `6792` |
| **Webmin Port** | `12579` |
| **Odoo Version** | `17.0` |
| **Admin User** | `sysadmin` |
| **Odoo User** | `sys-erp` |
| **Default Password** | `Admin@#$1234` |

## Access URLs

Once installation completes, you can access the services using the following routes:

| Service | Access Details | Notes |
| :--- | :--- | :--- |
| **Odoo ERP** | `http://YOUR_IP` | Standard web access proxied through Nginx |
| **Odoo Direct** | `http://YOUR_IP:ODOO_PORT` | Direct server connection (bypassing Nginx proxy) |
| **Webmin** | `https://YOUR_IP:WEBMIN_PORT` | Administration panel (if selected during install) |
| **SSH** | `ssh -p SSH_PORT sysadmin@YOUR_IP` | Remote command-line connection |

### Default Configuration Example:
```text
Odoo:     http://192.168.1.100
Webmin:   https://192.168.1.100:12579
SSH:      ssh -p 8173 sysadmin@192.168.1.100
```

## Post-Installation Structure

### Secure Odoo Directory
```text
/opt/odoo-secure/
├── addons-custom/          Place your custom modules here
├── addons-external/        Third-party modules
├── config/
│   └── odoo.conf          Main configuration file
├── filestore/             Odoo documents and attachments
└── logs/
    └── odoo.log           Odoo logs
```

### Backup Directory
```text
/opt/backup/
├── odoo_db_YYYYMMDD_HHMMSS.sql      Database dumps
├── odoo_filestore_YYYYMMDD.tar.gz   File backups
├── odoo_addons_custom_YYYYMMDD.tar.gz Custom addons backup
└── configs_YYYYMMDD.tar.gz          System configurations
```

## Security Features

### Automatically Configured
- **Firewall (UFW)** - Restricted incoming access with only required ports open.
- **Custom SSH Port** - Configured to mitigate brute-force server scans.
- **Fail2Ban** - Integrated to monitor logs and ban malicious IPs automatically.
- **PostgreSQL** - Bound strictly to `localhost` and listening on a custom port.
- **Odoo** - Bound to a custom port behind a hardened Nginx reverse proxy.
- **Secure Permissions** - Applies strict directory ownership (`odoo:odoo`) and reading limits.
- **Automatic Updates** - Unattended upgrades are enabled for security patches.

### Recommended Manual Steps
- Set up SSH key-based authentication and disable password logins.
- Enable SSL/HTTPS with Let's Encrypt.
- Update the default passwords to complex credentials.

## Maintenance

### Check Service Status
```bash
sudo systemctl status postgresql nginx odoo webmin ssh fail2ban
```

### View Logs
- **Odoo Logs:**
  ```bash
  sudo journalctl -u odoo -f
  ```
- **System Logs:**
  ```bash
  sudo journalctl -f
  ```
- **Error Logs Only:**
  ```bash
  sudo journalctl -p err -f
  ```

### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Restart Services
```bash
sudo systemctl restart postgresql nginx odoo webmin fail2ban
```

### Manual Backup
```bash
sudo /opt/backup/backup-odoo.sh
```

### View Backup Status
```bash
ls -lah /opt/backup/
```
```bash
crontab -l  # Check scheduled backup cron jobs
```

## Troubleshooting

### Odoo Not Starting
1. **Check status logs:**
   ```bash
   sudo journalctl -u odoo -n 50
   ```
2. **Fix directory ownership permissions:**
   ```bash
   sudo chown -R odoo:odoo /opt/odoo-secure/
   ```
3. **Restart the Odoo service:**
   ```bash
   sudo systemctl restart odoo
   ```

### SSH Connection Refused
1. **Check firewall state:**
   ```bash
   sudo ufw status
   ```
2. **Verify the SSH service is active:**
   ```bash
   sudo systemctl status ssh
   ```
3. **Ensure your custom SSH port is allowed:**
   ```bash
   sudo ufw allow SSH_PORT/tcp
   sudo ufw reload
   ```

### PostgreSQL Connection Failed
1. **Check PostgreSQL service status:**
   ```bash
   sudo systemctl status postgresql
   ```
2. **Verify the custom database port is listening:**
   ```bash
   sudo ss -tlnp | grep POSTGRES_PORT
   ```
3. **Restart the PostgreSQL service:**
   ```bash
   sudo systemctl restart postgresql
   ```

### Port Already in Use
1. **Locate the PID using the port:**
   ```bash
   sudo lsof -i :PORT_NUMBER
   ```
2. **Kill the process holding the port:**
   ```bash
   sudo kill -9 PID
   ```

### Webmin Not Accessible
1. **Verify Webmin service status:**
   ```bash
   sudo systemctl status webmin
   ```
2. **Ensure Webmin is listening on the custom port:**
   ```bash
   sudo netstat -tlnp | grep WEBMIN_PORT
   ```
3. **Restart the Webmin service:**
   ```bash
   sudo systemctl restart webmin
   ```

## Uninstall

### Option 1: Complete Removal
> [!WARNING]
> This command sequence stops services, removes all application binaries, and permanently deletes all databases and directory data.

```bash
# Stop running services
sudo systemctl stop odoo postgresql nginx webmin

# Purge packages
sudo apt remove --purge odoo
sudo apt remove --purge postgresql*
sudo apt remove --purge nginx*
sudo apt remove --purge webmin

# Remove data and configuration directories
sudo rm -rf /opt/odoo-secure /opt/backup /etc/nginx/sites-available/systemerp.local

# Restore SSH configuration backup
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config

# Reboot server
sudo reboot
```

### Option 2: Keep Data, Remove Only Services
```bash
# Stop core services
sudo systemctl stop odoo postgresql

# Perform a quick backup before removal
sudo /opt/backup/backup-odoo.sh
```

## FAQ

#### Can I install multiple Odoo versions?
No. This installer sets up a single version of Odoo per system. You must deploy separate server instances to run multiple versions.

#### Can I change ports after installation?
Yes, but you will need to update:
1. Odoo config file: `/opt/odoo-secure/config/odoo.conf`
2. Nginx configuration file: `/etc/nginx/sites-available/DOMAIN_LOCAL`
3. SSH daemon config: `/etc/ssh/sshd_config`
4. Firewall ports: `UFW` rulesets