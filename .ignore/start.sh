#!/usr/bin/env bash

timestamp(){
    date
}
printf '<settings>\n  <localRepository>/workspace/guru-shifu-gitpod/m2-repository/</localRepository>\n</settings>\n' > /home/gitpod/.m2/settings.xml
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $DIR
touch .env
echo "REACT_APP_HOST_URL=https://8080-${GITPOD_WORKSPACE_URL#*//}" > .env
echo "$(timestamp) Running docker-compose up in detach mode.." >> initializationlog.txt
docker-compose -f docker-compose-gitpod.yml up -d --quiet-pull
echo "$(timestamp) Docker compose completed." >> initializationlog.txt
if [ $? == 0 ]
then
  echo "$(timestamp) Waiting for guru-shifu to start up.... "
  echo "$(timestamp) Waiting for guru-shifu to start up.... " >> initializationlog.txt
  until $(curl --output /dev/null --silent --head --fail http://localhost:8080/rectangle/feedback-history/); do
    printf "."  >> initializationlog.txt
    sleep 1
  done
  until $(curl --output /dev/null --silent --head --fail http://localhost:3000/); do
    printf "*" >> initializationlog.txt
    sleep 1
  done
  echo ""
  echo "$(timestamp) Guru-shifu started successfully..."  >> initializationlog.txt
fi
cd /workspace