#!/usr/bin/env bash

# Flame Installation Script for Proxmox VE
# Author: Adapted from community script
# License: MIT

# Load Community Functions from build.func
BUILD_FUNC_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func"
MISC_DIR="/tmp/proxmox_misc_functions"
mkdir -p "$MISC_DIR"

if wget -qO "$MISC_DIR/build.func" "$BUILD_FUNC_URL"; then
    source "$MISC_DIR/build.func"
else
    echo "Error: Failed to download community functions from $BUILD_FUNC_URL."
    exit 1
fi

# Verify that key functions are loaded
REQUIRED_FUNCTIONS=(color verb_ip6 catch_errors setting_up_container network_check update_os)
for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if ! declare -f "$func" > /dev/null; then
        echo "Error: Function $func not found. Check the community script dependencies."
        exit 1
    fi
done

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

# Run utility functions (assuming they are loaded correctly)
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
      - "/var/run
