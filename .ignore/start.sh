#!/usr/bin/env bash

timestamp(){
    date
}
printf '<settings>\n  <localRepository>/workspace/guru-shifu-gitpod/m2-repository/</localRepository>\n</settings>\n' > /home/gitpod/.m2/settings.xml
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $DIR
touch .env
echo "REACT_APP_HOST_URL=https://8080-${GITPOD_WORKSPACE_URL#*//}" > .env
echo "$(timestamp) Starting guru-shifu..."
echo "$(timestamp) Running docker-compose up in detach mode.."
docker-compose -f docker-compose-gitpod.yml up -d
echo "$(timestamp) Docker compose completed."
if [ $? == 0 ]
then
  echo "$(timestamp) Waiting for guru-shifu to start up.... "
  until $(curl --output /dev/null --silent --head --fail http://localhost:3000/); do
    printf "."
    sleep 1
  done
  echo "$(timestamp) Guru-shifu started successfully..."
fi
cd /workspace
