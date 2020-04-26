#!/usr/bin/python
# Save Script as : configure_ssl.py
# Disable host name verification
import sys

ADMIN_URL='t3://localhost:7001'
PATH_TO_SERVER='/Servers/'
PATH_TO_SSL='/SSL/'

print(sys.argv)
if len(sys.argv) < 4:
   sys.exit(1)

adminUsername=sys.argv[1]
adminPassword=sys.argv[2]
serverName=sys.argv[3]

if (adminUsername == "" or 
   adminPassword == "" or
   serverName == ""):
   sys.exit(1)

# Connect to the AdminServer.
connect(adminUsername, adminPassword, ADMIN_URL)

try:
   edit()
   startEdit()
   print "set keystore to "+serverName
   cd(PATH_TO_SERVER + serverName + PATH_TO_SSL + serverName)
   cmo.setHostnameVerificationIgnored(true)
   save()
   activate()
except:
   stopEdit('y')
   sys.exit(1)

disconnect()
sys.exit(0)