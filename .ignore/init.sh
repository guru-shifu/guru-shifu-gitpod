#!/usr/bin/env bash

timestamp(){
    date
}

echo "$(timestamp) Locating required resources..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $DIR
touch initializationlog.txt

IDTOKEN=null
GATEWAY_ENDPOINT=null
CLIENT_ID=null
HTTP_RESPONSE=null
HEADER1='X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth'
HEADER2='Content-Type: application/x-amz-json-1.1'

if [ $STAGE == "prod" ]
then
    echo "$(timestamp) Using Prod Artifact..." >> initializationlog.txt
    GATEWAY_ENDPOINT='https://slygfw4sw7.execute-api.ap-south-1.amazonaws.com/Prod/get-signed-url'
    CLIENT_ID=7r012t0noqgjoaarjuc1u21v85
elif [ $STAGE == "test" ]
then
    echo "$(timestamp) Using Test Artifact..." >> initializationlog.txt
    GATEWAY_ENDPOINT='https://ivcgd3sjsk.execute-api.ap-south-1.amazonaws.com/Prod/get-signed-url'
    CLIENT_ID=5jrqkesh41t56ragneqln5ilkl
else
    echo "$(timestamp) Using Dev Artifact..." >> initializationlog.txt
    GATEWAY_ENDPOINT='https://piqcbc19ya.execute-api.ap-south-1.amazonaws.com/Prod/get-signed-url'
    CLIENT_ID=233o8b28j9k1423sh0vgujvn3c
fi

getIdToken() {
  read -p "Enter your email : " USER_NAME
  read -s -p "Enter your password : " PASSWORD
  BODY='{"ClientId": "'"$CLIENT_ID"'","AuthParameters": {"USERNAME": "'"$USER_NAME"'","PASSWORD": "'"$PASSWORD"'"},"AuthFlow": "USER_PASSWORD_AUTH"}'
  HTTP_RESPONSE=$(curl -s -o response.txt -w "%{http_code}"  -XPOST -H "$HEADER1" -H "$HEADER2" -d "$BODY" 'https://cognito-idp.ap-south-1.amazonaws.com/')
  echo ""
}

echo ""
echo -e "\e[1;32mPlease Enter your Details Below\e[0m"
getIdToken

while [ $HTTP_RESPONSE != "200" ]; do
  cat response.txt | jq -r .message
  echo -e "\e[1;31m------------Enter valid credentials...--------------------\e[0m"
  getIdToken
done

echo -e "\e[1;32m------------User Authenticated...--------------------\e[0m"
echo ""

IDTOKEN=$(cat response.txt | jq -r .AuthenticationResult.IdToken)

HTTP_RESPONSE=$(curl -s -o signedurl.txt -w "%{http_code}" -H "Authorization: $IDTOKEN" $GATEWAY_ENDPOINT)

if [ $HTTP_RESPONSE != "200" ]
then
  echo -e "\e[1;31mResource Not Found ...\e[0m"
  rm response.txt
  exit 125
fi

ARTIFACT_URL=$(cat signedurl.txt)
rm response.txt
rm signedurl.txt

echo "Artifact url obtained....." >> initializationlog.txt 
echo ""
echo -e "\e[1;34m $(timestamp) --------- Downloading the artifacts ... --------------\e[0m"
curl  --output guru-shifu.tar.gz "$ARTIFACT_URL"
echo "$(timestamp) Artifact download complete." >> initializationlog.txt
echo ""
echo "Setting up guru shifu. This may take around 5 minutes...."

echo "$(timestamp) Unzipping guru-shifu tarball..." >> initializationlog.txt
tar -xf guru-shifu.tar.gz
echo "$(timestamp) Unzip complete" >> initializationlog.txt

echo "Docker build for fly way migrate"  >> initializationlog.txt
docker build -q -t guru-shifu-db-migrations -f Dockerfile-flyway .
echo "docker flyway build done..." >> initializationlog.txt

source guru-shifu-env-variables.txt 

echo "Building the backend image..." >> initializationlog.txt
docker build -q -t  guru-shifu-api \
  --build-arg REMOTE_URL=$REMOTE_URL \
  --build-arg ENABLE_JAR_REQUIREMENT=$ENABLE_JAR_REQUIREMENT \
  --build-arg REMOTE_USERPOOL_URL=$REMOTE_USERPOOL_URL \
  --build-arg USER_ID=$USER_ID \
  --build-arg USER_NAME=$USER_NAME \
  --build-arg HOME_DIR=$HOME_DIR \
  --build-arg GURU_SHIFU_VERSION=$GURU_SHIFU_VERSION -f Dockerfile-api .

echo "Backend image done" >> initializationlog.txt

echo "Building the frontend image...." >> initializationlog.txt
docker build -q -t guru-shifu-ui \
  --build-arg GURU_SHIFU_VERSION=$GURU_SHIFU_VERSION \
  --build-arg ENABLE_JAR_REQUIREMENT=$ENABLE_JAR_REQUIREMENT \
  --build-arg CLIENT_ID=$CLIENT_ID --build-arg REMOTE_BATCHLIST_URL=$REMOTE_URL \
  --build-arg ENABLE_SIGNUP_FLOW=$ENABLE_SIGNUP_FLOW \
  --build-arg TARGET_ENV=${TARGET_ENV:="local"} -f Dockerfile-ui .

echo "Frontend Image done" >> initializationlog.txt

rm -R ui/
rm -R migration/
rm Dockerfile-api Dockerfile-ui Dockerfile-flyway 
rm guru-shifu-env-variables.txt guru-shifu.tar.gz  guru-shifu-boot-0.0.1-SNAPSHOT.jar

mkdir /workspace/guru-shifu-gitpod/m2-repository
printf '<settings>\n  <localRepository>/workspace/guru-shifu-gitpod/m2-repository/</localRepository>\n</settings>\n' > /home/gitpod/.m2/settings.xml