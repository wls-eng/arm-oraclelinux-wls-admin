#!/bin/bash

parametersPath=$1
githubUserName=$2
testbranchName=$3

cat <<EOF > ${parametersPath}
{
    "\$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "_artifactsLocation": {
            "value": "https://raw.githubusercontent.com/${githubUserName}/arm-oraclelinux-wls-admin/${testbranchName}/src/main/arm/"
        },
        "_artifactsLocationSasToken": {
            "value": ""
        },
        "adminPasswordOrKey": {
            "value": "GEN-UNIQUE"
        },
        "adminUsername": {
            "value": "GEN-UNIQUE"
        },
        "databaseType": {
            "value": "postgresql"
        },
        "dbPassword": {
            "value": "GEN-UNIQUE"
        },
        "dbUser": {
            "value": "GEN-UNIQUE"
        },
        "dsConnectionURL": {
            "value": "GEN-UNIQUE"
        },
        "enableAAD": {
            "value": false
        },
        "enableDB": {
            "value": true
        },
        "jdbcDataSourceName": {
            "value": "jdbc/postgresql"
        },
        "wlsPassword": {
            "value": "GEN-UNIQUE"
        },
        "wlsUserName": {
            "value": "GEN-UNIQUE"
        }
    }
}
EOF
