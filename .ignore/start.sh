#!/usr/bin/env bash

timestamp(){
    date
}
printf '<settings>\n  <localRepository>/workspace/guru-shifu-gitpod/m2-repository/</localRepository>\n</settings>\n' > /home/gitpod/.m2/settings.xml
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $DIR

echo "installing serve" >> initializationlog.txt
npm install -g serve >> initializationlog.txt

touch .env
echo "REACT_APP_HOST_URL=https://8080-${GITPOD_WORKSPACE_URL#*//}" > .env
echo "$(timestamp) Running docker-compose up in detach mode.." >> initializationlog.txt
docker-compose -f docker-compose-gitpod.yml up -d --quiet-pull
echo "$(timestamp) Docker compose completed." >> initializationlog.txt

echo "Replace backend url env variable" >> initializationlog.txt
source .env
source host-url.txt
sed -i "s|$LOCAL_HOST_URL|$REACT_APP_HOST_URL|g" ./build/static/js/main.*.js
echo "export LOCAL_HOST_URL=$REACT_APP_HOST_URL" > host-url.txt

if [ $? == 0 ]
then
  echo -e "\e[1;34m $(timestamp) Waiting for guru-shifu to start up.... \e[0m"
  echo "$(timestamp) Waiting for guru-shifu to start up.... " >> initializationlog.txt
  until $(curl --output /dev/null --silent --head --fail http://localhost:8080/rectangle/feedback-history/); do
    printf "."  >> initializationlog.txt
    sleep 1
  done
  echo "$(timestamp) Guru-shifu Backend started..."  >> initializationlog.txt
fi
echo "$(timestamp) GuruShifu frontend starting"  >> initializationlog.txt
nohup bash -c "serve -s build 2>&1 &" && sleep 4

cd /workspace