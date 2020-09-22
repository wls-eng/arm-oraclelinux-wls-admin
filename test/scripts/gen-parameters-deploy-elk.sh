#!/bin/bash
#Generate parameters with value for deploying elk template independently

parametersPath=$1
adminVMName=$2
elasticsearchPassword=$3
elasticsearchURI=$4
elasticsearchUserName=$5
location=$6
wlsDomainName=$7
wlsusername=$8
wlspassword=$9
gitUserName=${10}
testbranchName=${11}

elasticsearchPort=${elasticsearchURI#*:}
elasticsearchURI=${elasticsearchURI%%:*}
echo "elasticsearchPort: ${elasticsearchPort}"
echo "elasticsearchURI: ${elasticsearchURI}"


cat <<EOF > ${parametersPath}
{
     "adminVMName":{
        "value": "${adminVMName}"
      },
      "elasticsearchPassword": {
        "value": "elasticsearchPassword"
      },
      "elasticsearchPort": {
        "value": "${elasticsearchPort}"
      },
      "elasticsearchURI": {
        "value": "${elasticsearchURI}"
      },
      "elasticsearchUserName": {
        "value": "${elasticsearchUserName}"
      },
      "location": {
        "value": "${location}"
      },
      "wlsDomainName": {
        "value": "${wlsDomainName}"
      },
      "wlsPassword": {
        "value": "${wlsPassword}"
      },
      "wlsUserName": {
        "value": "${wlsUserName}"
      },
      "_artifactsLocation":{
        "value": "https://raw.githubusercontent.com/${gitUserName}/arm-oraclelinux-wls-admin/${testbranchName}/src/main/arm/"
      }
    }
EOF
