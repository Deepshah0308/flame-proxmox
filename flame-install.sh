#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2024 Deep Shah
# License: MIT
# GitHub: https://github.com/Deepshah0308

function header_info {
clear
cat <<"EOF"
   ______
   / ____/__  ____  _______  _______
  / /_  / _ \/ __ \/ ___/ / / / ___/
 / __/ /  __/ / / / /  / /_/ (__  )
/_/    \___/_/ /_/_/   \__,_/____/

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

function update_script() {
header_info
if [[ ! -d /opt/${APP} ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_error "There is currently no update path available."
exit
msg_info "Updating ${APP}"
systemctl stop ${APP}
git clone https://github.com/pawelmalak/flame.git
cd flame || exit
gitVersionNumber=$(git rev-parse HEAD)

if [[ "${gitVersionNumber}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
  mkdir /opt/flame-data-backup
  cp -r "/opt/${APP}/data/" /opt/flame-data-backup/data
  if [[ ! -d /opt/flame-data-backup/data ]]; then msg_error "Backup of data folder failed! Exiting..."; rm -r /opt/flame-data-backup/; exit; fi 
  export DOTNET_CLI_TELEMETRY_OPTOUT=1
  dotnet publish -c Release -o "/opt/${APP}/" flame.csproj
  cp -r /opt/flame-data-backup/data/ "/opt/${APP}/"
  echo "${gitVersionNumber}" >"/opt/${APP}_version.txt"
  rm -r /opt/flame-data-backup/
  msg_ok "Updated ${APP}"
else
  msg_ok "No update required. ${APP} is already up to date"
fi
cd ..
rm -r flame/

systemctl start ${APP}
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         http://${IP}:5005 \n"
