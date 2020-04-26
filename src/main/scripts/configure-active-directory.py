#!/usr/bin/python
# Save Script as : configure_active_directory.py

import sys

ADMIN_URL='t3://localhost:7001'
LDAP_USER_NAME='sAMAccountName'
LDAP_USER_FROM_NAME_FILTER='(&(sAMAccountName=%u)(objectclass=user))'

print(sys.argv)
if len(sys.argv) < 10:
   sys.exit(1)

adminUsername=sys.argv[1]
adminPassword=sys.argv[2]
domainName=sys.argv[3]
providerName=sys.argv[4]
adPassword=sys.argv[5]
adPrincipal=sys.argv[6]
adHost=sys.argv[7]
adPort=sys.argv[8]
adGroupBaseDN=sys.argv[9]
adUserBaseDN=sys.argv[10]

if(adminUsername == "" or 
   adminPassword == "" or 
   domainName == "" or
   providerName == "" or
   adPassword == "" or 
   adPrincipal == "" or
   adHost == "" or 
   adPort == "" or
   adGroupBaseDN == "" or 
   adUserBaseDN == ""):
   sys.exit(1)

# Connect to the AdminServer.
connect(adminUsername, adminPassword, ADMIN_URL)

try:
   edit()
   startEdit()
   # Configure DefaultAuthenticator.
   cd('/SecurityConfiguration/' + domainName + '/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
   cmo.setControlFlag('SUFFICIENT')

   # Configure Active Directory.
   cd('/SecurityConfiguration/' + domainName + '/Realms/myrealm')
   cmo.createAuthenticationProvider(providerName, 'weblogic.security.providers.authentication.ActiveDirectoryAuthenticator')

   cd('/SecurityConfiguration/' + domainName + '/Realms/myrealm/AuthenticationProviders/' + providerName)
   cmo.setControlFlag('OPTIONAL')

   cd('/SecurityConfiguration/' + domainName + '/Realms/myrealm')
   set('AuthenticationProviders',jarray.array([ObjectName('Security:Name=myrealm' + providerName), 
      ObjectName('Security:Name=myrealmDefaultAuthenticator'), 
      ObjectName('Security:Name=myrealmDefaultIdentityAsserter')], ObjectName))


   cd('/SecurityConfiguration/' + domainName + '/Realms/myrealm/AuthenticationProviders/' + providerName)
   cmo.setControlFlag('SUFFICIENT')
   cmo.setUserNameAttribute(LDAP_USER_NAME)
   cmo.setUserFromNameFilter(LDAP_USER_FROM_NAME_FILTER)
   cmo.setPrincipal(adPrincipal)
   cmo.setHost(adHost)
   set('Credential', adPassword)
   cmo.setGroupBaseDN(adGroupBaseDN)
   cmo.setUserBaseDN(adUserBaseDN)
   cmo.setPort(int(adPort))
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