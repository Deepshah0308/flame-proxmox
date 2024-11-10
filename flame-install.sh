#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2024 Deep Shah
# License: MIT
# GitHub: https://github.com/Deepshah0308

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

header_info
echo -e "Loading..."
APP="Flame"
var_disk="4"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function install_flame() {
  header_info
  msg_info "Installing dependencies"
  apt update && apt install -y curl git docker.io

  msg_info "Setting up Flame Docker container"

  # Ensure the Flame directory exists for persistent storage
  mkdir -p /opt/${APP}/data

  # Run the Flame Docker container
  docker run -d \
    --name=${APP} \
    -p 5005:5005 \
    -v /opt/${APP}/data:/app/data \
    -e PASSWORD=flame_password \
    pawelmalak/flame

  # Check if the container started successfully
  if docker ps | grep -q ${APP}; then
    msg_ok "Flame container is running."
    
    # Retrieve Proxmox container's IP address
    PROXMOX_IP=$(hostname -I | awk '{print $1}')
    
    if [[ -z "${PROXMOX_IP}" ]]; then
      msg_error "Failed to retrieve the Proxmox container's IP address. Please check network settings."
    else
      msg_ok "Flame is reachable at: http://${PROXMOX_IP}:5005"
    fi
  else
    msg_error "Flame container did not start. Please check Docker logs for more information."
    exit 1
  fi
}

function update_script() {
  header_info
  if [[ ! -d /opt/${APP} ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  msg_info "Updating ${APP}"

  cd /opt/${APP} || exit
  docker stop ${APP}
  docker rm ${APP}
  docker pull pawelmalak/flame
  docker run -d \
    --name=${APP} \
    -p 5005:5005 \
    -v /opt/${APP}/data:/app/data \
    -e PASSWORD=flame_password \
    pawelmalak/flame
  msg_ok "${APP} update completed"
}

start
build_container
description
install_flame

msg_ok "Installation Completed Successfully!"
echo -e "${APP} should be reachable by going to the following URL:
         http://${PROXMOX_IP}:5005 \n"
