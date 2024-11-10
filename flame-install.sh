#!/usr/bin/env bash

# Flame Installation Script for Proxmox VE
# Author: Adapted from community script
# License: MIT

# Source Community Functions directly from GitHub
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Header Function
function header_info {
clear
cat <<"EOF"
______ _       ___  ___  ___ _____ 
|  ___| |     / _ \ |  \/  ||  ___|
| |_  | |    / /_\ \| .  . || |__  
|  _| | |    |  _  || |\/| ||  __| 
| |   | |____| | | || |  | || |___ 
\_|   \_____/\_| |_/\_|  |_/\____/ 
                                   
EOF
}

# Display the header
header_info

# Utility Functions (loaded from build.func)
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Variables
FLAME_DATA_PATH="/opt/flame/data"
FLAME_PORT=5005

# Prompt for the Flame password
echo "Please enter a password for Flame (will be used for accessing the Flame interface):"
read -s FLAME_PASSWORD
echo "Password set."

msg_info "Installing Dependencies"
$STD apt-get install -y curl sudo mc
msg_ok "Installed Dependencies"

# Install Docker
msg_info "Installing Docker"
curl -fsSL https://get.docker.com -o get-docker.sh
$STD sh get-docker.sh
msg_ok "Docker Installed"

# Install Docker Compose
msg_info "Installing Docker Compose"
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
msg_ok "Docker Compose Installed"

# Setup Flame Data Directory
msg_info "Setting up Flame data directory"
mkdir -p "$FLAME_DATA_PATH"
msg_ok "Data Directory Created"

# Create Docker Compose Configuration
msg_info "Configuring Docker Compose for Flame"
FLAME_COMPOSE_FILE="/opt/flame/docker-compose.yml"
mkdir -p "$(dirname "$FLAME_COMPOSE_FILE")"
cat <<EOF > "$FLAME_COMPOSE_FILE"
version: '3.6'

services:
  flame:
    image: pawelmalak/flame
    container_name: flame
    ports:
      - "$FLAME_PORT:5005"
    volumes:
      - "$FLAME_DATA_PATH:/app/data"
      - "/var/run/docker.sock:/var/run/docker.sock" # optional for Docker integration
    environment:
      - PASSWORD=$FLAME_PASSWORD
    restart: unless-stopped
EOF
msg_ok "Docker Compose Configuration Created"

# Run Flame with Docker Compose
msg_info "Starting Flame"
cd "$(dirname "$FLAME_COMPOSE_FILE")" || exit
$STD docker-compose up -d
msg_ok "Flame Started"

# Cleanup
msg_info "Cleaning up"
rm get-docker.sh
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned up installation files"

# Display MOTD or customization function (if defined)
motd_ssh
customize

echo "Flame is now installed and running on port $FLAME_PORT."
echo "Access Flame at http://<Proxmox_IP>:$FLAME_PORT with the password you set."
