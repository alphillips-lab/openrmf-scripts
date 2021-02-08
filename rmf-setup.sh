#!/bin/bash

#
# You need to run this as sudo or root more than likely for it to work.
# Unless you have allowed docker and docker-compose extra permissions for
# your user.
#

NC="\e[0m"
RED="\e[0;31m"
CYAN="\e[0;36m"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

if [ "$EUID" -ne 0 ]; then
  echo -e "${BOLD}${RED}You are not running this script as root.${NC}${NORMAL}"
  echo -e "$CYAN"
  echo "  This script uses docker which frequently requires sudo to run."
  echo "  Therefore, please either edit this script to remove this check"
  echo "  or run the script using sudo."
  echo -e "$NC"
  exit
fi

echo
echo -e "${BOLD}Keycloak Server IP${NORMAL}"
echo -e "$CYAN"
echo "  The Keycloak container is running in a docker container. It is"
echo "  probably called 'keycloak_keycloak_1' or something similiar."
echo
echo "  In 'docker ps' it shows as listening on port 9001."
echo -e "$NC"
read -p "  What is it's IP address? " keyip #>> $pathtohome/openrmf-Install.log

##ACCOUNT AUTHENTICATE
echo
echo -e "${BOLD}OpenRMF Account Details${NORMAL}"
echo -e "$CYAN"
echo "  Input the user name and password of the OpenRMF Keycloak when prompted"
echo "  Administrator (Default admin is openrmf-admin, password supplied at hand-off)"
echo
read -p "Username: " rmfadm
read -s -p "Password (no echo): " password


echo
echo "Discovering local Keycloak Docker Container..."
keycontainer="$(docker ps | grep "jboss/keycloak:" | awk '{ print $1 }')"
echo "keycontainer: $keycontainer"
##END Locate Keycloak Container ID

##BEGIN Authenticate to Keycloak server
echo
echo "Authenticating to Keycloak Master Realm..."
docker exec $keycontainer /opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user $rmfadm --password $password
##END Authenticate to Keycloak server

##BEGIN Disable SSL Requirement
echo
echo "Setting Require SSL to ALL REQUESTS (required)..."
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh update realms/openrmf --set 'sslRequired=none' #change to all requests for ssl
##END Disable SSL Requirement

##BEGIN Redirect Requirement
echo
echo "Changing Redirect URI to Current IP ($keyip)..."
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh update realms/openrmf --set 'redirectUris=["http://'$keyip':8080/*"]' #change redirect uri
##END Redirect Requirement
