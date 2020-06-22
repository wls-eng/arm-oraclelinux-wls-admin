#!/bin/bash
#This file is to set local environment variables according to image sku.
#imageName: offer name of the image
#imageVersion: latest version of the image
#imagePublisher: publisher
#Example of using the variable: echo ${imageName} ${imageVersion} ${imagePublisher}

sku=$1

if [ ${sku} == "owls-122130-8u131-ol73" ];
then
    echo "##[set-env name=imageName;]weblogic-122130-jdk8u131-ol73"
    echo "##[set-env name=imageVersion;]1.1.6"
    echo "##[set-env name=imagePublisher;]oracle"
fi

if [ ${sku} == "owls-122130-8u131-ol74" ];
then
    echo "##[set-env name=imageName;]weblogic-122130-jdk8u131-ol74"
    echo "##[set-env name=imageVersion;]1.1.1"
    echo "##[set-env name=imagePublisher;]oracle"
fi

if [ ${sku} == "owls-122140-8u251-ol76" ];
then
    echo "##[set-env name=imageName;]weblogic-122140-jdk8u251-ol76"
    echo "##[set-env name=imageVersion;]1.1.1"
    echo "##[set-env name=imagePublisher;]oracle"
fi

if [ ${sku} == "owls-141100-11_07-ol76" ];
then
    echo "##[set-env name=imageName;]weblogic-141100-jdk11_07-ol76"
    echo "##[set-env name=imageVersion;]1.1.1"
    echo "##[set-env name=imagePublisher;]oracle"
fi

if [ ${sku} == "owls-141100-8u251-ol76" ];
then
    echo "##[set-env name=imageName;]weblogic-141100-jdk8u251-ol76"
    echo "##[set-env name=imageVersion;]1.1.1"
    echo "##[set-env name=imagePublisher;]oracle"
fi


