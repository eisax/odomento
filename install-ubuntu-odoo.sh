#!/bin/bash

#################################################################################
# AUTOMATED INSTALLATION SCRIPT - UBUNTU SERVER + SECURED ODOO
# Version: 2.4 - Odoo 19.0 Fix on Ubuntu 22.04 (Jammy)
# Date: August 2025 - Support Odoo 14.0, 15.0, 16.0, 17.0, 18.0, 19.0
# Fixes: lxml, PostgreSQL port, Database Manager
# NEW: Webmin optional, Custom domain support

## You are never fully dressed without a smile :)

#email me at josphatkndhlovu@gmail.com
#################################################################################

# Colors for logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

#################################################################################
# INTERACTIVE CONFIGURATION - DEFAULT VALUES
#################################################################################

# Network parameters (fixed)
DEFAULT_DOMAIN_LOCAL="systemerp.local"
SERVER_NAME="systemerp-prod"
ADMIN_USER="sysadmin"
ODOO_USER="sys-erp"

# Default values
DEFAULT_SSH_PORT="8173"
DEFAULT_WEBMIN_PORT="12579"
DEFAULT_ODOO_PORT="9017"
DEFAULT_ODOO_LONGPOLL_PORT="8072"
DEFAULT_POSTGRES_PORT="6792"
DEFAULT_ODOO_VERSION="17.0"
DEFAULT_PASSWORD="Pass@123"

# Network interface (auto-detected)
NETWORK_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
DETECTED_IP=$(ip addr show $NETWORK_INTERFACE | grep "inet " | awk '{print $2}' | cut -d/ -f1)
DETECTED_GATEWAY=$(ip route | grep default | awk '{print $3}')

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              INTERACTIVE SERVER CONFIGURATION                    ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Press ENTER to use the default value"
echo ""

# Domain configuration
echo " DOMAIN CONFIGURATION:"
read -p "Domain name (e.g., erp.mycompany.com) [$DEFAULT_DOMAIN_LOCAL]: " DOMAIN_LOCAL
DOMAIN_LOCAL=${DOMAIN_LOCAL:-$DEFAULT_DOMAIN_LOCAL}
echo ""

# Port configuration
echo "🔧 PORT CONFIGURATION:"
read -p "SSH Port [$DEFAULT_SSH_PORT]: " SSH_PORT
SSH_PORT=${SSH_PORT:-$DEFAULT_SSH_PORT}

read -p "Odoo Port [$DEFAULT_ODOO_PORT]: " ODOO_PORT
ODOO_PORT=${ODOO_PORT:-$DEFAULT_ODOO_PORT}

read -p "PostgreSQL Port [$DEFAULT_POSTGRES_PORT]: " POSTGRES_PORT
POSTGRES_PORT=${POSTGRES_PORT:-$DEFAULT_POSTGRES_PORT}

# Webmin installation option
echo ""
echo "  WEBMIN INSTALLATION OPTION:"
echo "   Webmin is a web-based system administration tool"
echo "   It allows you to manage your server via web browser"
echo "   Recommended for beginners, optional for advanced users"
echo ""
read -p "Install Webmin? (y/N): " INSTALL_WEBMIN
INSTALL_WEBMIN=${INSTALL_WEBMIN:-n}

if [[ $INSTALL_WEBMIN =~ ^[Yy]$ ]]; then
    read -p "Webmin Port [$DEFAULT_WEBMIN_PORT]: " WEBMIN_PORT
    WEBMIN_PORT=${WEBMIN_PORT:-$DEFAULT_WEBMIN_PORT}
else
    WEBMIN_PORT=$DEFAULT_WEBMIN_PORT
    log "Webmin installation skipped"
fi

# Odoo version configuration with validation
echo ""
echo " ODOO VERSION:"
echo "   Available versions: 14.0, 15.0, 16.0, 17.0, 18.0, 19.0"
while true; do
    read -p "Odoo Version [$DEFAULT_ODOO_VERSION]: " ODOO_VERSION
    ODOO_VERSION=${ODOO_VERSION:-$DEFAULT_ODOO_VERSION}
    
    # Version validation
    if [[ "$ODOO_VERSION" =~ ^(14\.0|15\.0|16\.0|17\.0|18\.0|19\.0)$ ]]; then
        break
    else
        echo "Invalid version. Choose: 14.0, 15.0, 16.0, 17.0, 18.0 or 19.0"
    fi
done

# Network configuration
echo ""
echo " NETWORK CONFIGURATION:"
echo "   Detected interface: $NETWORK_INTERFACE"
echo "   Detected IP       : $DETECTED_IP"
echo "   Detected gateway  : $DETECTED_GATEWAY"
read -p "Server IP address [$DETECTED_IP]: " CURRENT_IP
CURRENT_IP=${CURRENT_IP:-$DETECTED_IP}

read -p "Gateway [$DETECTED_GATEWAY]: " GATEWAY
GATEWAY=${GATEWAY:-$DETECTED_GATEWAY}

# Password configuration
echo ""
echo "PASSWORD CONFIGURATION:"
echo "   Default password: $DEFAULT_PASSWORD"
echo ""

read -s -p "PostgreSQL password (postgres) [$DEFAULT_PASSWORD]: " POSTGRES_ADMIN_PASS
echo ""
POSTGRES_ADMIN_PASS=${POSTGRES_ADMIN_PASS:-$DEFAULT_PASSWORD}

read -s -p "PostgreSQL password (sys-erp) [$DEFAULT_PASSWORD]: " POSTGRES_USER_PASS
echo ""
POSTGRES_USER_PASS=${POSTGRES_USER_PASS:-$DEFAULT_PASSWORD}

read -s -p "Odoo Master Password [$DEFAULT_PASSWORD]: " ODOO_MASTER_PASS
echo ""
ODOO_MASTER_PASS=${ODOO_MASTER_PASS:-$DEFAULT_PASSWORD}

# Longpolling port automatic (Odoo port + 1000)
ODOO_LONGPOLL_PORT=$((ODOO_PORT + 1000))

# Confirmation of parameters
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    DETECTED CONFIGURATION                       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Network interface  : $NETWORK_INTERFACE"
echo "Configured IP      : $CURRENT_IP"
echo "Gateway            : $GATEWAY"
echo "Domain             : $DOMAIN_LOCAL"
echo "SSH Port           : $SSH_PORT"
if [[ $INSTALL_WEBMIN =~ ^[Yy]$ ]]; then
    echo "Webmin Port        : $WEBMIN_PORT"
else
    echo "Webmin             : SKIPPED (not installed)"
fi
echo "Odoo Port          : $ODOO_PORT"
echo "PostgreSQL Port    : $POSTGRES_PORT"
echo "Odoo Version       : $ODOO_VERSION"
echo ""
echo "    AUTOMATED INSTALLATION IN PROGRESS..."
echo "    The script will now run without interruption."
echo "    No manual intervention will be required."
echo "    Estimated duration: 15-30 minutes depending on Internet connection."
echo ""
read -p "Continue with this configuration? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

echo ""
log " Starting automated installation..."
log " Please wait, no intervention required..."

#################################################################################
# NON-INTERACTIVE CONFIGURATION
#################################################################################

# Configuration to avoid any user interaction
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

# Debconf configuration for automatic mode
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
echo 'debconf debconf/priority select critical' | debconf-set-selections

# Configuration of automatic service restarts
mkdir -p /etc/needrestart/conf.d
cat > /etc/needrestart/conf.d/50-local.conf << 'EOF'
# Automatically restart services without asking
$nrconf{restart} = 'a';
$nrconf{kernelhints} = 0;
$nrconf{ucodehints} = 0;
EOF

#################################################################################
# STEP 1: SYSTEM UPDATE AND TOOL INSTALLATION
#################################################################################

log "Starting automated installation..."
log "STEP 1/5: System update and tool installation (non-interactive mode)"

# System update in automatic mode
log "Updating system..."
apt update && DEBIAN_FRONTEND=noninteractive apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || error "System update failed"

# Batch installation of system tools
log "Installing essential system tools..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    ufw fail2ban unattended-upgrades nano rsyslog cron \
    iputils-ping dnsutils net-tools curl wget git equivs \
    python3-pip python3-dev python3-venv \
    libxml2-dev libxslt1-dev libevent-dev libsasl2-dev libldap2-dev \
    pkg-config libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev \
    libfreetype6-dev liblcms2-dev libwebp-dev libharfbuzz-dev \
    libfribidi-dev libxcb1-dev fontconfig libxrender1 xfonts-75dpi xfonts-base \
    -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || error "Tool installation failed"

# wkhtmltopdf installation (official version for better compatibility)
log "Installing wkhtmltopdf (Odoo PDF generation)..."
WKHTMLTOPDF_VERSION="0.12.6.1-2"
WKHTMLTOPDF_URL="https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}.jammy_amd64.deb"
cd /tmp
wget -q $WKHTMLTOPDF_URL -O wkhtmltox.deb || warning "wkhtmltopdf download failed, installing from apt"
if [ -f "wkhtmltox.deb" ]; then
    DEBIAN_FRONTEND=noninteractive dpkg -i wkhtmltox.deb || true
    DEBIAN_FRONTEND=noninteractive apt-get install -f -y
    log " wkhtmltopdf installed from official sources"
else
    DEBIAN_FRONTEND=noninteractive apt install -y wkhtmltopdf
    log " wkhtmltopdf installed from apt"
fi

# Python dependencies installation for advanced Odoo modules
log "Installing Python dependencies for Odoo modules..."
pip3 install --upgrade pip

# NEW: Specific dependencies based on Odoo version
if [[ "$ODOO_VERSION" == "14.0" ]] || [[ "$ODOO_VERSION" == "15.0" ]]; then
    log " Installing Python dependencies for Odoo $ODOO_VERSION (compatible versions)..."
    
    # Critical dependencies with fixed versions for Odoo 14.0/15.0
    pip3 install \
        'lxml==4.9.3' \
        'lxml_html_clean==0.1.0' \
        'Pillow>=8.0.0,<10.0.0' \
        'Werkzeug>=2.0.0,<2.1.0' \
        'reportlab>=3.5.0,<4.0.0' \
        requests \
        cryptography \
        'xlsxwriter>=1.3.0' \
        'xlrd>=1.2.0,<2.1.0' \
        'openpyxl>=3.0.0' \
        'python-dateutil>=2.8.0' \
        pytz \
        qrcode \
        dropbox \
        pyncclient \
        nextcloud-api-wrapper \
        boto3 \
        paramiko || warning "Some Python dependencies failed (continuing...)"
        
else
    log "Installing Python dependencies for Odoo $ODOO_VERSION (recent versions)..."
    
    # Dependencies with recent versions for Odoo 16.0+
    pip3 install \
        lxml \
        'lxml[html_clean]' \
        lxml_html_clean \
        Pillow \
        requests \
        cryptography \
        reportlab \
        'qrcode[pil]' \
        xlsxwriter \
        xlrd \
        openpyxl \
        python-dateutil \
        pytz \
        dropbox \
        pyncclient \
        nextcloud-api-wrapper \
        boto3 \
        paramiko || warning "Some Python dependencies failed (continuing...)"
fi

log " System tools and Python dependencies installed successfully"

#################################################################################
# STEP 2: COMPLETE FIREWALL CONFIGURATION
#################################################################################

log "STEP 2/5: Firewall configuration with all custom ports"

# Local network detection (used to restrict Odoo, PostgreSQL and Webmin)
# We derive /24 from $CURRENT_IP already validated by the user
LOCAL_NETWORK=$(echo $CURRENT_IP | awk -F'.' '{print $1"."$2"."$3".0/24"}')
log "Detected local network: $LOCAL_NETWORK (restricting internal access)"

# UFW configuration
log "Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Opening custom ports
log "Opening SSH port: $SSH_PORT"
ufw allow $SSH_PORT/tcp comment 'SSH Custom'

log "Opening HTTP/HTTPS ports"
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

log "Opening Odoo port: $ODOO_PORT (local network only)"
ufw allow from $LOCAL_NETWORK to any port $ODOO_PORT comment 'Odoo Local Network Only'

log "Opening PostgreSQL port: $POSTGRES_PORT (localhost only)"
ufw allow from 127.0.0.1 to any port $POSTGRES_PORT comment 'PostgreSQL Localhost Only'

if [[ $INSTALL_WEBMIN =~ ^[Yy]$ ]]; then
    log "Opening Webmin port: $WEBMIN_PORT (local network only)"
    ufw allow from $LOCAL_NETWORK to any port $WEBMIN_PORT comment 'Webmin Local Network Only'
fi

# Enable firewall
ufw --force enable || error "Firewall activation failed"

# Verification of applied rules
log " Checking UFW restriction rules..."
ufw status numbered | grep -E "($ODOO_PORT|$POSTGRES_PORT|$WEBMIN_PORT)" || true

log " Firewall configured successfully"

# Static IP configuration
log "Configuring static IP..."
cat > /etc/netplan/00-installer-config.yaml << EOF
network:
  version: 2
  ethernets:
    $NETWORK_INTERFACE:
      dhcp4: no
      addresses:
        - $CURRENT_IP/24
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4, $GATEWAY]
EOF

netplan apply || warning "Network configuration failed (continuing...)"

# Local domain configuration
log "Configuring domain: $DOMAIN_LOCAL"

# Backup /etc/hosts before modification
cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)

# Add entries with duplicate check (idempotent)
grep -qF "$CURRENT_IP    $DOMAIN_LOCAL" /etc/hosts || echo "$CURRENT_IP    $DOMAIN_LOCAL" >> /etc/hosts
grep -qF "$CURRENT_IP    $SERVER_NAME.$DOMAIN_LOCAL" /etc/hosts || echo "$CURRENT_IP    $SERVER_NAME.$DOMAIN_LOCAL" >> /etc/hosts

# Local resolution for wkhtmltopdf (fix PDF timeout after router change / NAT loopback)
# wkhtmltopdf must be able to reach Odoo via localhost without depending on external routing
log "Adding wkhtmltopdf local resolution (fix NAT loopback / PDF timeout)..."
grep -qF "127.0.0.1 $DOMAIN_LOCAL" /etc/hosts || echo "127.0.0.1 $DOMAIN_LOCAL" >> /etc/hosts

log " Network configuration completed"

#################################################################################
# STEP 3: POSTGRESQL INSTALLATION
#################################################################################

log "STEP 3/5: PostgreSQL installation and configuration"

# PostgreSQL installation
log "Installing PostgreSQL..."
DEBIAN_FRONTEND=noninteractive apt install -y postgresql postgresql-contrib -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || error "PostgreSQL installation failed"
systemctl enable postgresql

# User configuration
log "Configuring PostgreSQL users..."
sudo -u postgres psql << EOF
ALTER USER postgres PASSWORD '$POSTGRES_ADMIN_PASS';
CREATE USER "$ODOO_USER" WITH CREATEDB;
ALTER USER "$ODOO_USER" PASSWORD '$POSTGRES_USER_PASS';
\q
EOF

# Custom PostgreSQL port configuration
log "Configuring PostgreSQL port: $POSTGRES_PORT"

# FIX: Find the correct PostgreSQL configuration file
POSTGRES_VERSION=$(ls /etc/postgresql/ | head -n1)
POSTGRES_CONF="/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"

log "PostgreSQL file found: $POSTGRES_CONF"

# Modify port (handle commented and uncommented cases)
sed -i "s/#port = 5432/port = $POSTGRES_PORT/" "$POSTGRES_CONF"
sed -i "s/port = 5432/port = $POSTGRES_PORT/" "$POSTGRES_CONF"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" "$POSTGRES_CONF"
sed -i "s/listen_addresses = 'localhost'/listen_addresses = 'localhost'/" "$POSTGRES_CONF"

# Verify change
if grep -q "port = $POSTGRES_PORT" "$POSTGRES_CONF"; then
    log " PostgreSQL port modified successfully: $POSTGRES_PORT"
else
    warning " Manual PostgreSQL port modification required"
    # Force adding port if not found
    echo "port = $POSTGRES_PORT" >> "$POSTGRES_CONF"
fi

systemctl restart postgresql || error "PostgreSQL restart failed"

# Verify PostgreSQL is listening on the correct port
sleep 5
if ss -tlnp | grep ":$POSTGRES_PORT" >/dev/null; then
    log " PostgreSQL is correctly listening on port $POSTGRES_PORT"
else
    error " PostgreSQL is not listening on port $POSTGRES_PORT"
fi

log " PostgreSQL configured on port $POSTGRES_PORT"

#################################################################################
# STEP 4: NGINX + ODOO + WEBMIN (OPTIONAL) INSTALLATION
#################################################################################

log "STEP 4/5: Installing Nginx, Odoo $ODOO_VERSION and Webmin (optional)"

# Nginx installation
log "Installing Nginx..."
DEBIAN_FRONTEND=noninteractive apt install -y nginx certbot python3-certbot-nginx -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || error "Nginx installation failed"
systemctl enable nginx

# Nginx reverse proxy configuration with custom domain
log "Configuring Nginx reverse proxy for Odoo with domain: $DOMAIN_LOCAL"
log "Optimizing for large uploads (databases, modules)..."
cat > /etc/nginx/sites-available/$DOMAIN_LOCAL << EOF
server {
    listen 80;
    server_name $DOMAIN_LOCAL $CURRENT_IP;
    
    # Increase limits for Odoo (large databases)
    client_max_body_size 1024M;
    client_body_timeout 300s;
    client_header_timeout 300s;
    
    # Proxy timeouts for long operations
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    send_timeout 300s;
    
    # Redirect to Odoo
    location / {
        proxy_pass http://127.0.0.1:$ODOO_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # Headers for large uploads
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # WebSocket for Odoo (longpolling)
    location /websocket {
        proxy_pass http://127.0.0.1:$ODOO_LONGPOLL_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Odoo static files handling
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://127.0.0.1:$ODOO_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/$DOMAIN_LOCAL /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl restart nginx || error "Nginx configuration failed"

# Odoo installation with correct method based on version
log " Installing Odoo $ODOO_VERSION (adapted method)..."

# FIX: Wait for ongoing apt processes to finish
log "Checking for ongoing apt processes..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    log " Waiting for ongoing apt processes to finish..."
    sleep 5
done

# Clean residual locks
log "Cleaning apt locks..."
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/dpkg/lock*

# Remove existing Odoo sources to avoid conflicts
rm -f /etc/apt/sources.list.d/odoo.list
rm -f /usr/share/keyrings/odoo-archive-keyring.gpg

if [[ "$ODOO_VERSION" == "14.0" ]] || [[ "$ODOO_VERSION" == "15.0" ]]; then
    # Special method for Odoo 14.0 and 15.0 (different GPG and sources)
    log "🔧 Installing Odoo $ODOO_VERSION with specialized method..."
    
    # Download and install GPG key (fixed method)
    wget -q -O - https://nightly.odoo.com/odoo.key | gpg --dearmor -o /usr/share/keyrings/odoo-archive-keyring.gpg || error "Odoo GPG key download failed"
    
    # Add repository with correct syntax
    echo "deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/$ODOO_VERSION/nightly/deb/ ./" > /etc/apt/sources.list.d/odoo.list
    
    # Update and install with lock management
    log "Updating packages and installing Odoo $ODOO_VERSION..."
    
    # Wait for locks to be released before update
    while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        log " Waiting for lock release for update..."
        sleep 3
    done
    
    DEBIAN_FRONTEND=noninteractive apt-get update || error "Odoo package update failed"
    
    # Wait for locks to be released before installation
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        log " Waiting for lock release for installation..."
        sleep 3
    done
    
    DEBIAN_FRONTEND=noninteractive apt-get install -y odoo -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || error "Odoo $ODOO_VERSION installation failed"
    
else
    # Standard method for Odoo 16.0, 17.0, 18.0, 19.0
    log "🔧 Installing Odoo $ODOO_VERSION with standard method..."
    
    wget -O - https://nightly.odoo.com/odoo.key | gpg --dearmor -o /usr/share/keyrings/odoo-archive-keyring.gpg || error "Odoo GPG key download failed"
    echo "deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/$ODOO_VERSION/nightly/deb/ ./" | tee /etc/apt/sources.list.d/odoo.list
    
    # Wait for locks to be released
    while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        log " Waiting for lock release for update..."
        sleep 3
    done
    
    DEBIAN_FRONTEND=noninteractive apt-get update || error "Odoo package update failed"
    
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        log " Waiting for lock release for installation..."
        sleep 3
    done
    
    # ODOO 19.0 FIX ON UBUNTU 22.04 (JAMMY)
    # python3-lxml-html-clean missing on Jammy - phantom package via equivs
    if [[ "$ODOO_VERSION" == "19.0" ]]; then
        UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "unknown")
        if [[ "$UBUNTU_CODENAME" == "jammy" ]]; then
            log "FIX: Creating python3-lxml-html-clean package for Ubuntu 22.04..."
            mkdir -p /tmp/lxml-clean-fix && cd /tmp/lxml-clean-fix
            cat > lxml-html-clean.ctl << EQUIVS_EOF
Section: misc
Priority: optional
Standards-Version: 3.9.2
Package: python3-lxml-html-clean
Version: 0.4.1
Maintainer: OdooFix <admin@local>
Architecture: all
Description: Dummy package - lxml_html_clean installed via pip
EQUIVS_EOF
            equivs-build lxml-html-clean.ctl
            dpkg -i python3-lxml-html-clean_0.4.1_all.deb || true
            cd /tmp
            log "Phantom package python3-lxml-html-clean installed"
        fi
    fi
    DEBIAN_FRONTEND=noninteractive apt-get install -y odoo -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || error "Odoo $ODOO_VERSION installation failed"
fi

log " Odoo $ODOO_VERSION installed successfully"

# Creating secure Odoo structure
log "Creating secure Odoo structure..."
mkdir -p /opt/odoo-secure/{addons-custom,addons-external,config,logs,filestore}

# Secure Odoo configuration
log "Configuring Odoo with custom ports and secure addons..."

# Port syntax detection based on Odoo version
# - Odoo 14.0/15.0 : xmlrpc_port + longpolling_port
# - Odoo 16.0+     : http_port + gevent_port
# - Odoo 18.0/19.0 : http_port + gevent_port (without report_url, option removed)
if [[ "$ODOO_VERSION" == "14.0" ]] || [[ "$ODOO_VERSION" == "15.0" ]]; then
    CONF_PORT="xmlrpc_port = $ODOO_PORT"
    CONF_LONGPOLL="longpolling_port = $ODOO_LONGPOLL_PORT"
    CONF_REPORT_URL="report_url = http://127.0.0.1:$ODOO_PORT"
elif [[ "$ODOO_VERSION" == "18.0" ]] || [[ "$ODOO_VERSION" == "19.0" ]]; then
    CONF_PORT="http_port = $ODOO_PORT"
    CONF_LONGPOLL="gevent_port = $ODOO_LONGPOLL_PORT"
    CONF_REPORT_URL="# report_url not supported in v18/v19"
else
    # 16.0 and 17.0
    CONF_PORT="http_port = $ODOO_PORT"
    CONF_LONGPOLL="gevent_port = $ODOO_LONGPOLL_PORT"
    CONF_REPORT_URL="report_url = http://127.0.0.1:$ODOO_PORT"
fi

cat > /opt/odoo-secure/config/odoo.conf << EOF
[options]
# Custom ports
$CONF_PORT
$CONF_LONGPOLL

# PostgreSQL database
db_host = localhost
db_port = $POSTGRES_PORT
db_user = $ODOO_USER
db_password = $POSTGRES_USER_PASS

# Odoo master password
admin_passwd = $ODOO_MASTER_PASS

# Database interface
list_db = True
dbfilter = ^.*$
db_template = template0
proxy_mode = True

# Fix wkhtmltopdf: local resolution (NAT loopback)
$CONF_REPORT_URL

# Secure addons
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/opt/odoo-secure/addons-external,/opt/odoo-secure/addons-custom

# Logs and data
logfile = /opt/odoo-secure/logs/odoo.log
data_dir = /opt/odoo-secure/filestore

# Security and performance
without_demo = True
max_cron_threads = 1
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
server_wide_modules = base,web
EOF

# CRITICAL FIX: Correct permissions FOR ODOO USER
log "Applying secure permissions..."
chown -R odoo:odoo /opt/odoo-secure/
chmod 750 /opt/odoo-secure/addons-custom/
chmod 750 /opt/odoo-secure/addons-external/
chmod 750 /opt/odoo-secure/config/
chmod 750 /opt/odoo-secure/filestore/
chmod 755 /opt/odoo-secure/logs/
chmod 640 /opt/odoo-secure/config/odoo.conf

# Link to secure configuration AND link permissions
ln -sf /opt/odoo-secure/config/odoo.conf /etc/odoo/odoo.conf
chown odoo:odoo /etc/odoo/odoo.conf

# Test Odoo configuration before starting
log "Testing Odoo configuration..."

# Differentiated test based on Odoo version
if [[ "$ODOO_VERSION" == "14.0" ]] || [[ "$ODOO_VERSION" == "15.0" ]]; then
    # Special test for Odoo 14.0/15.0 (lxml check)
    log " Specific test for Odoo $ODOO_VERSION (lxml compatibility check)..."
    
    # Test critical dependencies
    if python3 -c "from lxml.html import clean; print('lxml.html.clean: OK')" 2>/dev/null; then
        log " lxml.html.clean compatible"
    else
        warning " lxml problem detected, automatic fix..."
        pip3 install --force-reinstall 'lxml==4.9.3' 'lxml_html_clean==0.1.0'
    fi
    
    # Test Odoo with timeout
    if timeout 30 sudo -u odoo odoo --config=/etc/odoo/odoo.conf --test-enable --stop-after-init --logfile=/tmp/odoo-test.log 2>/dev/null; then
        log " Odoo $ODOO_VERSION configuration valid"
    else
        warning " Odoo $ODOO_VERSION test - Checking logs..."
        if [ -f "/tmp/odoo-test.log" ]; then
            grep -i "lxml\|AttributeError\|ImportError" /tmp/odoo-test.log | head -3 || true
        fi
    fi
else
    # Standard test for Odoo 16.0+
    if timeout 30 sudo -u odoo odoo --config=/etc/odoo/odoo.conf --test-enable --stop-after-init --logfile=/tmp/odoo-test.log 2>/dev/null; then
        log " Odoo $ODOO_VERSION configuration valid"
    else
        warning " Odoo configuration test in progress, checking..."
        if [ -f "/tmp/odoo-test.log" ]; then
            grep -i "error\|critical\|fatal" /tmp/odoo-test.log | head -5 || true
        fi
    fi
fi

# Restart Odoo with robust verification based on version
log "Starting Odoo $ODOO_VERSION service..."
systemctl stop odoo || true
sleep 5

# Special handling for Odoo 14.0/15.0 (slower startup)
if [[ "$ODOO_VERSION" == "14.0" ]] || [[ "$ODOO_VERSION" == "15.0" ]]; then
    log " Starting Odoo $ODOO_VERSION (optimized startup for older versions)..."
    systemctl start odoo
    sleep 20  # Extra time for Odoo 14.0/15.0
    
    # Verification with lxml diagnosis if failure
    for i in {1..5}; do
        if systemctl is-active --quiet odoo; then
            log " Odoo $ODOO_VERSION started successfully (attempt $i/5)"
            break
        else
            warning "Attempt $i/5: Odoo $ODOO_VERSION not started..."
            
            # Special lxml diagnosis for first attempts
            if [ $i -le 2 ]; then
                log "🔍 Checking lxml compatibility..."
                if ! python3 -c "from lxml.html import clean; print('OK')" 2>/dev/null; then
                    log "🔧 Automatic lxml fix in progress..."
                    pip3 install --force-reinstall 'lxml==4.9.3' 'lxml_html_clean==0.1.0'
                fi
            fi
            
            systemctl restart odoo
            sleep 20
        fi
        
        if [ $i -eq 5 ]; then
            warning " Odoo $ODOO_VERSION failed after 5 attempts, diagnosing..."
            systemctl status odoo
            journalctl -u odoo -n 10 --no-pager
            log " Manual check recommended: sudo journalctl -u odoo -f"
        fi
    done
else
    # Standard startup for Odoo 16.0+
    log " Starting Odoo $ODOO_VERSION (standard startup)..."
    systemctl start odoo
    sleep 15
    
    for i in {1..5}; do
        if systemctl is-active --quiet odoo; then
            log " Odoo $ODOO_VERSION started successfully (attempt $i/5)"
            break
        else
            warning "Attempt $i/5: Odoo $ODOO_VERSION not started, retrying..."
            systemctl restart odoo
            sleep 15
        fi
        
        if [ $i -eq 5 ]; then
            warning " Odoo $ODOO_VERSION failed after 5 attempts, diagnosing..."
            systemctl status odoo
            journalctl -u odoo -n 10 --no-pager
        fi
    done
fi

# Webmin installation (optional)
if [[ $INSTALL_WEBMIN =~ ^[Yy]$ ]]; then
    log "Installing Webmin..."
    wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
    echo "deb http://download.webmin.com/download/repository sarge contrib" | tee -a /etc/apt/sources.list
    DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt install -y webmin -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || error "Webmin installation failed"
    
    # Webmin port configuration
    log "Configuring Webmin port: $WEBMIN_PORT"
    sed -i "s/port=10000/port=$WEBMIN_PORT/" /etc/webmin/miniserv.conf
    sed -i "s/listen=10000/listen=$WEBMIN_PORT/" /etc/webmin/miniserv.conf
    
    systemctl restart webmin || error "Webmin restart failed"
    log " Webmin installed and configured on port $WEBMIN_PORT"
else
    log " Webmin installation skipped as requested"
fi

log " Nginx, Odoo $ODOO_VERSION and Webmin (optional) installed and configured"

#################################################################################
# STEP 5: FINAL SECURITY + AUTOMATIC PASSWORD DISABLE
#################################################################################

log "STEP 5/5: Final system security hardening"

# Verify/Create SSH admin user
log "Checking administrator user: $ADMIN_USER..."
if id "$ADMIN_USER" &>/dev/null; then
    log " User $ADMIN_USER already exists — no creation needed."
else
    log "  User $ADMIN_USER not found. Creating..."
    useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
    echo "$ADMIN_USER:$DEFAULT_PASSWORD" | chpasswd
    log " User $ADMIN_USER created (temporary password: $DEFAULT_PASSWORD)"
    log "  Remember to change this password on first login!"
fi

# Secure SSH configuration (keep passwords for now)
log "Configuring secure SSH on port $SSH_PORT..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

cat > /etc/ssh/sshd_config << EOF
# Secure SSH configuration
Port $SSH_PORT
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication yes
MaxAuthTries 3
AllowUsers $ADMIN_USER
ClientAliveInterval 300
ClientAliveCountMax 2

# Secure protocols
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
LoginGraceTime 60
StrictModes yes
RSAAuthentication yes

# Additional security
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

systemctl restart ssh || error "SSH restart failed"

# Fail2ban configuration
log "Configuring Fail2ban..."
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = $SSH_PORT
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

# Enable traditional logs
systemctl enable rsyslog
systemctl start rsyslog
touch /var/log/auth.log
chown syslog:adm /var/log/auth.log
chmod 640 /var/log/auth.log

systemctl enable fail2ban
systemctl restart fail2ban || error "Fail2ban startup failed"

# Automatic backup configuration
log "Configuring automatic backup..."
mkdir -p /opt/backup
chown $ADMIN_USER:$ADMIN_USER /opt/backup

cat > /opt/backup/backup-odoo.sh << EOF
#!/bin/bash
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backup"

# Database backup
PGPASSWORD='$POSTGRES_USER_PASS' pg_dump -h localhost -p $POSTGRES_PORT -U $ODOO_USER postgres > \$BACKUP_DIR/odoo_db_\${DATE}.sql

# Secure Odoo filestore backup
tar -czf \$BACKUP_DIR/odoo_filestore_\${DATE}.tar.gz /opt/odoo-secure/filestore/ 2>/dev/null

# Custom addons backup
tar -czf \$BACKUP_DIR/odoo_addons_custom_\${DATE}.tar.gz /opt/odoo-secure/addons-custom/ 2>/dev/null

# Secure configurations backup
tar -czf \$BACKUP_DIR/configs_\${DATE}.tar.gz /opt/odoo-secure/config/ /etc/nginx/sites-available/ /etc/ssh/sshd_config /etc/fail2ban/jail.local 2>/dev/null

# Cleanup (keep 7 days)
find \$BACKUP_DIR -name "*.sql" -mtime +7 -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: \${DATE}"
EOF

chmod +x /opt/backup/backup-odoo.sh

# Automatic cron
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/backup/backup-odoo.sh >> /var/log/backup.log 2>&1") | crontab -

# Create installation documentation on server
log "Creating installation documentation..."
cat > /opt/backup/GUIDE-INSTALLATION-SystemERP.md << 'EOFDOC'
#  PRACTICAL INSTALLATION GUIDE - SystemERP

##  Ubuntu Server + Odoo Installation in 5 minutes

### QUICK INSTALLATION

#### Prerequisites (30 seconds)
```bash
sudo apt update
sudo apt install -y nano wget curl