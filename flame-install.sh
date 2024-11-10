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

  msg_info "Cloning Flame repository"
  git clone https://github.com/pawelmalak/flame.git /opt/${APP}

  if [[ -d "/opt/${APP}" ]]; then
    msg_info "Setting up Flame container"
    docker run -d \
      --name=${APP} \
      -p 5005:5005 \
      -v /opt/${APP}/data:/app/data \
      -e PASSWORD=flame_password \
      pawelmalak/flame

    # Check if container started successfully
    if docker ps | grep -q ${APP}; then
      msg_ok "Flame container is running."
      
      # Retrieve container IP
      FLAME_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${APP})
      
      if [[ -z "${FLAME_IP}" ]]; then
        msg_error "Failed to retrieve the IP address. Please check Docker network settings."
      else
        msg_ok "Flame is reachable at: http://${FLAME_IP}:5005"
      fi
    else
      msg_error "Flame container did not start. Please check Docker logs for more information."
      exit 1
    fi
  else
    msg_error "Failed to clone Flame repository. Please check network connection and repository URL."
    exit 1
  fi
}

function update_script() {
  header_info
  if [[ ! -d /opt/${APP} ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  msg_info "Updating ${APP}"

  cd /opt/${APP} || exit
  git pull
  docker-compose down
  docker-compose up -d
  msg_ok "${APP} update completed"
}

start
build_container
description
install_flame

msg_ok "Installation Completed Successfully!"
echo -e "${APP} should be reachable by going to the following URL (if IP retrieval succeeded):
         http://${FLAME_IP}:5005 \n"
