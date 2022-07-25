#!/usr/bin/env bash

timestamp(){
    date
}
printf '<settings>\n  <localRepository>/workspace/guru-shifu-gitpod/.m2/repository/</localRepository>\n</settings>\n' > /home/gitpod/.m2/settings.xml
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $DIR

source guru-shifu-env-variables.txt 
export HOME=/workspace/guru-shifu-gitpod/

touch .env
echo "REACT_APP_HOST_URL=https://8080-${GITPOD_WORKSPACE_URL#*//}" > .env
echo "$(timestamp) Running docker-compose up in detach mode.." >> initializationlog.log
docker-compose -f docker-compose-gitpod.yml up -d --quiet-pull
echo -e "\e[1;34m $(timestamp) Waiting for guru-shifu to start up.... \e[0m"
STARTED=1
until [ $STARTED == 0 ];
do
docker ps -a --filter "exited=0" | grep "guru-shifu-db-migrations" >> sqllogs.log
STARTED=$?
sleep 1
done

echo "$(timestamp) Docker compose completed." >> initializationlog.log

echo "Replace backend url env variable" >> initializationlog.log
source .env
source host-url.txt
sed -i "s|$LOCAL_HOST_URL|$REACT_APP_HOST_URL|g" ./build/static/js/main.*.js
echo "export LOCAL_HOST_URL=$REACT_APP_HOST_URL" > host-url.txt

echo "Starting GuruShifu backend..." >> initializationlog.log

nohup java -jar guru-shifu-boot-0.0.1-SNAPSHOT.jar &> springlog.log &

if [ $? == 0 ]
then
  echo "$(timestamp) Waiting for guru-shifu to start up.... " >> initializationlog.log
  until $(curl -X OPTIONS --output /dev/null --silent --head --fail http://localhost:8080/rectangle/feedback-history/); do
    printf "."  >> initializationlog.log
    sleep 1
  done
  echo "$(timestamp) Guru-shifu Backend started..."  >> initializationlog.log
fi
echo "$(timestamp) GuruShifu frontend starting"  >> initializationlog.log
nohup serve -s build &> ui.log &
cd /workspace
