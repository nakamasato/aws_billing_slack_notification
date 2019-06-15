#!/bin/bash

STACK=NotifyBilling
###### TARGET BUCKET, SLACK_URL, AWS PROFILE #####
while getopts p: OPT
do
    case $OPT in
        p)  PROFILE=$OPTARG
            ;;
        *)  echo "usage: ./destroy.sh -p <AWS profile>" 1>&2
            exit 1
            ;;
    esac
done

PROFILE="${PROFILE:-default}"

read -p "do you really destroy stack $STACK ? (y/n)" YN_LOADSETTING

if [ "${YN_LOADSETTING}" != "y" ]; then
    echo "stop destroying"
    exit 1
fi

aws cloudformation delete-stack --stack-name $STACK --profile $PROFILE

