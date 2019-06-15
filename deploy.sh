#!/bin/bash

set -eu

###### TARGET BUCKET, SLACK_URL, AWS PROFILE #####
while getopts b:s:p: OPT
do
    case $OPT in
        b)  BUCKET=$OPTARG
            ;;
        s)  SLACK_URL=$OPTARG
            ;;
        p)  PROFILE=$OPTARG
            ;;
        *)  echo "usage: ./deploy.sh -b <bucket> -s <slack_url> -p <AWS profile>" 1>&2
            exit 1
            ;;
    esac
done

PROFILE="${PROFILE:-default}"
export AWS_DEFAULT_PROFILE=$PROFILE
echo "BUCKET: ${BUCKET:-}, PROFILE: $PROFILE"

if [ -z "${BUCKET:-}" -o -z "${SLACK_URL:-}" ];then
    echo "usage: ./deploy.sh -b <bucket> -s <slack_url>"
    exit 1
fi


if aws s3 ls "s3://$BUCKET" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb s3://$BUCKET
elif aws s3 ls "s3://$BUCKET" 2>&1 | grep -q 'AccessDenied'; then
    echo $BUCKET already owned by others. please use other name.
    exit 1
else
    echo $BUCKET already exists. no need to create
fi


cd notify_billing
pip install -r requirements.txt -t ./
cd -


sam build

sam package \
    --output-template-file packaged.yaml \
    --s3-bucket $BUCKET \
    --template-file template.yaml

sam deploy \
    --template-file packaged.yaml \
    --stack-name NotifyBilling \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides SlackWebhookUrl=$SLACK_URL
