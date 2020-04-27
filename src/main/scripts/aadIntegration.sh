#Function to output message to StdErr
function echo_stderr ()
{
    echo "$@" >&2
}

#Function to display usage message
function usage()
{
  echo_stderr "./aadIntegration.sh <wlsUserName> <wlsPassword> <wlsDomainName> <wlsLDAPProviderName> <addsServerHost> <aadsPortNumber> <wlsLDAPPrincipal> <wlsLDAPPrincipalPassword> <wlsLDAPUserBaseDN> <wlsLDAPGroupBaseDN> <oracleHome> <adminVMName> <wlsAdminPort> <wlsLDAPSSLCertificate> <addsPublicIP> <adminPassword> <wlsAdminServerName>"  
}

function validateInput()
{
    if [[ -z "$wlsUserName" || -z "$wlsPassword" ]]
    then
        echo_stderr "wlsUserName or wlsPassword is required. "
        exit 1
    fi

    if [ -z "$wlsDomainName" ];
    then
        echo_stderr "wlsDomainName is required. "
    fi

    if [ -z "$adProviderName" ];
    then
        echo_stderr "adProviderName is required. "
    fi

    if [ -z "$adPrincipal" ];
    then
        echo_stderr "adPrincipal is required. "
    fi

    if [ -z "$adPassword" ];
    then
        echo_stderr "adPassword is required. "
    fi

    if [ -z "$adServerHost" ];
    then
        echo_stderr "adServerHost is required. "
    fi

    if [ -z "$adServerPort" ];
    then
        echo_stderr "adServerPort is required. "
    fi

    if [ -z "$adGroupBaseDN" ];
    then
        echo_stderr "adGroupBaseDN is required. "
    fi

    if [ -z "$adUserBaseDN" ];
    then
        echo_stderr "adUserBaseDN is required. "
    fi

    if [ -z "$oracleHome" ];
    then
        echo_stderr "oracleHome is required. "
    fi

    if [ -z "$wlsAdminHost" ];
    then
        echo_stderr "wlsAdminHost is required. "
    fi

    if [ -z "$wlsAdminPort" ];
    then
        echo_stderr "wlsAdminPort is required. "
    fi

    if [ -z "$vituralMachinePassword" ];
    then
        echo_stderr "vituralMachinePassword is required. "
    fi

    if [ -z "$wlsADSSLCer" ];
    then
        echo_stderr "wlsADSSLCer is required. "
    fi

    if [ -z "$wlsLDAPPublicIP" ];
    then
        echo_stderr "wlsLDAPPublicIP is required. "
    fi

    if [ -z "$vituralMachinePassword" ];
    then
        echo_stderr "vituralMachinePassword is required. "
    fi

    if [ -z "$wlsAdminServerName" ];
    then
        echo_stderr "wlsAdminServerName is required. "
    fi
}

function createAADProvider_model()
{
    cat <<EOF >${SCRIPT_PWD}/configure-active-directory.py
connect('$wlsUserName','$wlsPassword','t3://$wlsAdminURL')
try:
   edit()
   startEdit()
   # Configure DefaultAuthenticator.
   cd('/SecurityConfiguration/' + '${wlsDomainName}' + '/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
   cmo.setControlFlag('SUFFICIENT')

   # Configure Active Directory.
   cd('/SecurityConfiguration/' + '${wlsDomainName}' + '/Realms/myrealm')
   cmo.createAuthenticationProvider('${adProviderName}', 'weblogic.security.providers.authentication.ActiveDirectoryAuthenticator')

   cd('/SecurityConfiguration/' + '${wlsDomainName}' + '/Realms/myrealm/AuthenticationProviders/' + '${adProviderName}')
   cmo.setControlFlag('OPTIONAL')

   cd('/SecurityConfiguration/' + '${wlsDomainName}' + '/Realms/myrealm')
   set('AuthenticationProviders',jarray.array([ObjectName('Security:Name=myrealm' + '${adProviderName}'), 
      ObjectName('Security:Name=myrealmDefaultAuthenticator'), 
      ObjectName('Security:Name=myrealmDefaultIdentityAsserter')], ObjectName))


   cd('/SecurityConfiguration/' + '${wlsDomainName}' + '/Realms/myrealm/AuthenticationProviders/' + '${adProviderName}')
   cmo.setControlFlag('SUFFICIENT')
   cmo.setUserNameAttribute('${LDAP_USER_NAME}')
   cmo.setUserFromNameFilter('${LDAP_USER_FROM_NAME_FILTER}')
   cmo.setPrincipal('${adPrincipal}')
   cmo.setHost('${adServerHost}')
   set('Credential', '${adPassword}')
   cmo.setGroupBaseDN('${adGroupBaseDN}')
   cmo.setUserBaseDN('${adUserBaseDN}')
   cmo.setPort(int('${adServerPort}'))
   cmo.setSSLEnabled(true)

   # for performance tuning
   cmo.setMaxGroupMembershipSearchLevel(1)
   cmo.setGroupMembershipSearching('limited')
   cmo.setUseTokenGroupsForGroupMembershipLookup(true)
   cmo.setResultsTimeLimit(300)
   cmo.setConnectionRetryLimit(5)
   cmo.setConnectTimeout(120)
   cmo.setCacheTTL(300)
   cmo.setConnectionPoolSize(60)
   cmo.setCacheSize(4000)
   cmo.setGroupHierarchyCacheTTL(300)
   cmo.setEnableSIDtoGroupLookupCaching(true)

   save()
   activate()
except:
   stopEdit('y')
   sys.exit(1)

disconnect()
sys.exit(0)
EOF
}

function createSSL_model()
{
    cat <<EOF >${SCRIPT_PWD}/configure-ssl.py
# Connect to the AdminServer.
connect('$wlsUserName','$wlsPassword','t3://$wlsAdminURL')
try:
   edit()
   startEdit()
   print "set keystore to ${wlsAdminServerName}"
   cd('/Servers/${wlsAdminServerName}/SSL/${wlsAdminServerName}')
   cmo.setHostnameVerificationIgnored(true)
   save()
   activate()
except:
   stopEdit('y')
   sys.exit(1)

disconnect()
sys.exit(0)
EOF
}

function mapLDAPHostWithPublicIP()
{
    echo "map LDAP host with pubilc IP"
    # change to superuser
    echo "${vituralMachinePassword}"
    sudo -S su -
    sudo echo "${wlsLDAPPublicIP}  ${adServerHost}" >> /etc/hosts
}

function parseLDAPCertificate()
{
    echo "create key store"
    cer_begin=0
    cer_size=${#wlsADSSLCer}
    cer_line_len=64
    mkdir ${SCRIPT_PWD}/security
    touch ${SCRIPT_PWD}/security/AzureADLDAPCerBase64String.txt
    while [ ${cer_begin} -lt ${cer_size} ]
    do
        cer_sub=${wlsADSSLCer:$cer_begin:$cer_line_len}
        echo ${cer_sub} >> ${SCRIPT_PWD}/security/AzureADLDAPCerBase64String.txt
        cer_begin=$((cer_begin+64))
    done

    openssl base64 -d -in ${SCRIPT_PWD}/security/AzureADLDAPCerBase64String.txt -out ${SCRIPT_PWD}/security/AzureADTrust.cer
    export addsCertificate=${SCRIPT_PWD}/security/AzureADTrust.cer
}

function importAADCertificate()
{
    # import the key to java security 
    . $oracleHome/oracle_common/common/bin/setWlstEnv.sh
    java_cacerts_path=${JAVA_HOME}/jre/lib/security/cacerts
    sudo ${JAVA_HOME}/bin/keytool -noprompt -import -alias aadtrust -file ${addsCertificate} -keystore ${java_cacerts_path} -storepass changeit

}

function configureSSL()
{
    echo "configure ladp ssl"
    . $oracleHome/oracle_common/common/bin/setWlstEnv.sh
    java $WLST_ARGS weblogic.WLST ${SCRIPT_PWD}/configure-ssl.py 

    errorCode=$?
    if [ $errorCode -eq 1 ]
    then 
        echo "Exception occurs during SSL configuration, please check."
        exit 1
    fi
}

function configureAzureActiveDirectory()
{
    echo "create Azure Active Directory provider"
    . $oracleHome/oracle_common/common/bin/setWlstEnv.sh
    java $WLST_ARGS weblogic.WLST ${SCRIPT_PWD}/configure-active-directory.py 

    errorCode=$?
    if [ $errorCode -eq 1 ]
    then 
        echo "Exception occurs during Azure Active Directory configuration, please check."
        exit 1
    fi
}

function restartAdminServerService()
{
     echo "Restart weblogic admin server service"
     sudo systemctl stop wls_admin
     sudo systemctl start wls_admin
}

#This function to check admin server status 
function wait_for_admin()
{
    #check admin server status
    count=1
    export CHECK_URL="http://$wlsAdminURL/weblogic/ready"
    status=`curl --insecure -ILs $CHECK_URL | tac | grep -m1 HTTP/1.1 | awk {'print $2'}`
    echo "Check admin server status"
    while [[ "$status" != "200" ]]
    do
    echo "."
    count=$((count+1))
    if [ $count -le 30 ];
    then
        sleep 1m
    else
        echo "Error : Maximum attempts exceeded while checking admin server status"
        exit 1
    fi
    status=`curl --insecure -ILs $CHECK_URL | tac | grep -m1 HTTP/1.1 | awk {'print $2'}`
    if [ "$status" == "200" ];
    then
        echo "WebLogic Server is running..."
        break
    fi
    done  
}

function cleanup()
{
    echo "Cleaning up temporary files..."
    rm -f ${SCRIPT_PWD}/configure-ssl.py
    rm -f ${SCRIPT_PWD}/configure-active-directory.py 
    rm -rf ${SCRIPT_PWD}/security/*
    echo "Cleanup completed."
}

export LDAP_USER_NAME='sAMAccountName'
export LDAP_USER_FROM_NAME_FILTER='(&(sAMAccountName=%u)(objectclass=user))'
export SCRIPT_PWD=`pwd`

if [ $# -ne 17 ]
then
    usage
	exit 1
fi

export wlsUserName=$1
export wlsPassword=$2
export wlsDomainName=$3
export adProviderName=$4
export adServerHost=$5
export adServerPort=$6
export adPrincipal=$7
export adPassword=$8
export adGroupBaseDN=$9
export adUserBaseDN=${10}
export oracleHome=${11}
export wlsAdminHost=${12}
export wlsAdminPort=${13}
export wlsADSSLCer="${14}"
export wlsLDAPPublicIP="${15}"
export vituralMachinePassword="${16}"
export wlsAdminServerName=${17}
export wlsAdminURL=$wlsAdminHost:$wlsAdminPort


echo "check status of admin server"
wait_for_admin

echo "start to configure Azure Active Directory"
createAADProvider_model
createSSL_model
mapLDAPHostWithPublicIP
parseLDAPCertificate
importAADCertificate
configureSSL
configureAzureActiveDirectory
restartAdminServerService

echo "Waiting for admin server to be available"
wait_for_admin
echo "Weblogic admin server is up and running"

