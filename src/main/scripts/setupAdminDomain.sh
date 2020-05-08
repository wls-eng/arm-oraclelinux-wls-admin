#!/bin/bash

#Function to output message to StdErr
function echo_stderr ()
{
    echo "$@" >&2
}

#Function to display usage message
function usage()
{
  echo_stderr "./setupAdminDomain.sh <wlsDomainName> <wlsUserName> <wlsPassword> <wlsAdminHost> <oracleHome>"  
}

function installUtilities()
{
    echo "Installing zip unzip wget vnc-server rng-tools bind-utils"
    sudo yum install -y zip unzip wget vnc-server rng-tools bind-utils

 #Setting up rngd utils
    attempt=1
    while [[ $attempt -lt 4 ]]
    do
       echo "Starting rngd service attempt $attempt"
       sudo systemctl start rngd
       attempt=`expr $attempt + 1`
       sudo systemctl status rngd | grep running
       if [[ $? == 0 ]]; 
       then
          echo "rngd utility service started successfully"
          break
       fi
       sleep 1m
    done  
}

function downloadUsingWget()
{
   downloadURL=$1
   filename=${downloadURL##*/}
   for in in {1..5}
   do
     wget $downloadURL
     if [ $? != 0 ];
     then
        echo "$filename Driver Download failed on $downloadURL. Trying again..."
	rm -f $filename
     else 
        echo "$filename Driver Downloaded successfully"
        break
     fi
   done
}

#Function to cleanup all temporary files
function cleanup()
{
    echo "Cleaning up temporary files..."

    rm -rf $DOMAIN_PATH/admin-domain.yaml
    rm -rf $DOMAIN_PATH/weblogic-deploy.zip
    rm -rf $DOMAIN_PATH/weblogic-deploy
    rm -rf $DOMAIN_PATH/deploy-app.yaml
    rm -rf $DOMAIN_PATH/shoppingcart.zip
 
    echo "Cleanup completed."
}

#Creates weblogic deployment model for admin domain
function create_admin_model()
{
    echo "Creating admin domain model"
    cat <<EOF >$DOMAIN_PATH/admin-domain.yaml
domainInfo:
   AdminUserName: "$wlsUserName"
   AdminPassword: "$wlsPassword"
   ServerStartMode: prod
topology:
   Name: "$wlsDomainName"
   AdminServerName: admin
   Server:
        'admin':
            ListenPort: $wlsAdminPort
            RestartDelaySeconds: 10
            SSL:
               ListenPort: $wlsSSLAdminPort
               Enabled: true
EOF
}

# This function to create model for sample application deployment 
function create_app_deploy_model()
{

    echo "Creating deploying applicaton model"
    cat <<EOF >$DOMAIN_PATH/deploy-app.yaml
domainInfo:
   AdminUserName: "$wlsUserName"
   AdminPassword: "$wlsPassword"
   ServerStartMode: prod
appDeployments:
   Application:
     shoppingcart :
          SourcePath: $DOMAIN_PATH/shoppingcart.war
          Target: admin
          ModuleType: war
EOF
}

#Function to create Admin Only Domain
function create_adminDomain()
{
    echo "Creating Admin Only Domain"
    echo "Creating domain path /u01/domains"
    echo "Downloading weblogic-deploy-tool"

    DOMAIN_PATH="/u01/domains"
    sudo mkdir -p $DOMAIN_PATH
    sudo rm -rf $DOMAIN_PATH/*

    cd $DOMAIN_PATH
    wget -q $WEBLOGIC_DEPLOY_TOOL  
    if [[ $? != 0 ]]; then
       echo "Error : Downloading weblogic-deploy-tool failed"
       exit 1
    fi
    sudo unzip -o weblogic-deploy.zip -d $DOMAIN_PATH
    create_admin_model
    sudo chown -R $username:$groupname $DOMAIN_PATH
    runuser -l oracle -c ". $oracleHome/oracle_common/common/bin/setWlstEnv.sh; $DOMAIN_PATH/weblogic-deploy/bin/createDomain.sh -oracle_home $oracleHome -domain_parent $DOMAIN_PATH  -domain_type WLS -model_file $DOMAIN_PATH/admin-domain.yaml"
    if [[ $? != 0 ]]; then
       echo "Error : Domain creation failed"
       exit 1
    fi
}

# Boot properties for admin server
function admin_boot_setup()
{
echo "Creating admin server boot properties"
 #Create the boot.properties directory
 mkdir -p "$DOMAIN_PATH/$wlsDomainName/servers/admin/security"
 echo "username=$wlsUserName" > "$DOMAIN_PATH/$wlsDomainName/servers/admin/security/boot.properties"
 echo "password=$wlsPassword" >> "$DOMAIN_PATH/$wlsDomainName/servers/admin/security/boot.properties"
 sudo chown -R $username:$groupname $DOMAIN_PATH/$wlsDomainName/servers
 echo "Completed admin server boot properties"
}

# Create adminserver as service
function create_adminserver_service()
{
echo "Creating weblogic admin server service"
cat <<EOF >/etc/systemd/system/wls_admin.service
[Unit]
Description=WebLogic Adminserver service
 
[Service]
Type=simple
WorkingDirectory="/u01/domains/$wlsDomainName"
ExecStart="/u01/domains/$wlsDomainName/startWebLogic.sh"
ExecStop="/u01/domains/$wlsDomainName/bin/stopWebLogic.sh"
User=oracle
Group=oracle
KillMode=process
LimitNOFILE=65535
 
[Install]
WantedBy=multi-user.target
EOF
echo "Completed weblogic admin server service"
}

#This function to wait for admin server 
function wait_for_admin()
{
 #wait for admin to start
count=1
export CHECK_URL="http://$wlsAdminURL/weblogic/ready"
status=`curl --insecure -ILs $CHECK_URL | tac | grep -m1 HTTP/1.1 | awk {'print $2'}`
while [[ "$status" != "200" ]]
do
  echo "Waiting for admin server to start"
  count=$((count+1))
  if [ $count -le 30 ];
  then
      sleep 1m
  else
     echo "Error : Maximum attempts exceeded while starting admin server"
     exit 1
  fi
  status=`curl --insecure -ILs $CHECK_URL | tac | grep -m1 HTTP/1.1 | awk {'print $2'}`
  if [ "$status" == "200" ];
  then
     echo "Server $wlsServerName started succesfully..."
     break
  fi
done  
}

#Function to deploy application in offline mode
#Sample shopping cart 
function deploy_sampleApp()
{
    create_app_deploy_model
	echo "Downloading and Deploying Sample Application"
	wget -q $samplApp
	sudo unzip -o shoppingcart.zip -d $DOMAIN_PATH
    sudo chown -R $username:$groupname $DOMAIN_PATH/shoppingcart.*
    runuser -l oracle -c ". $oracleHome/oracle_common/common/bin/setWlstEnv.sh; $DOMAIN_PATH/weblogic-deploy/bin/deployApps.sh -oracle_home $oracleHome -archive_file $DOMAIN_PATH/shoppingcart.war -domain_home $DOMAIN_PATH/$wlsDomainName -model_file  $DOMAIN_PATH/deploy-app.yaml"
	if [[ $? != 0 ]]; then
       echo "Error : Deploying application failed"
       exit 1
    fi
}

function validateInput()
{
    if [ -z "$wlsDomainName" ];
    then
        echo_stderr "wlsDomainName is required. "
        exit 1
    fi

    if [[ -z "$wlsUserName" || -z "$wlsPassword" ]]
    then
        echo_stderr "wlsUserName or wlsPassword is required. "
        exit 1
    fi

    if [ -z "$wlsAdminHost" ];
    then
        echo_stderr "wlsAdminHost is required. "
        exit 1
    fi

    if [ -z "$oracleHome" ];
    then
        echo_stderr "oracleHome is required. "
        exit 1
    fi
}

function enableAndStartAdminServerService()
{
    echo "Starting weblogic admin server as service"
    sudo systemctl enable wls_admin
    sudo systemctl daemon-reload
    sudo systemctl start wls_admin
}

#main script starts here

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BASE_DIR="$(readlink -f ${CURR_DIR})"

if [ $# -ne 5 ]
then
    usage
	exit 1
fi

export wlsDomainName="$1"
export wlsUserName="$2"
export wlsPassword="$3"
export wlsAdminHost="$4"
export oracleHome="$5"

validateInput

installUtilities

export WEBLOGIC_DEPLOY_TOOL=https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-1.8.1/weblogic-deploy.zip
export samplApp="https://www.oracle.com/webfolder/technetwork/tutorials/obe/fmw/wls/10g/r3/cluster/session_state/files/shoppingcart.zip"
export wlsAdminPort=7001
export wlsSSLAdminPort=7002
export wlsAdminURL="$wlsAdminHost:$wlsAdminPort"
export username="oracle"
export groupname="oracle"

export SCRIPT_PWD=`pwd`

setWlsEnv

create_adminDomain

deploy_sampleApp

cleanup

create_adminserver_service

admin_boot_setup

enableAndStartAdminServerService

echo "Waiting for admin server to be available"
wait_for_admin
echo "Weblogic admin server is up and running"