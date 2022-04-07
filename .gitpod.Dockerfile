FROM gitpod/workspace-full

RUN npm install -g serve 

RUN apt-get install -y java-15-amazon-corretto-jdk