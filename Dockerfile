# Base Image
FROM ubuntu 

RUN apt update
RUN apt install -y curl
RUN curl -sL https://deb.nodesource.com/setup_24.x -o /tmp/nodesource_setup.sh
RUN bash /tmp/nodesource_setup.sh
RUN apt install -y nodejs

# Copying the source code to docker
COPY index.js  home/app/index.js
COPY package-lock.json /home/app/package-lock.json
COPY package.json  /home/app/package.json

WORKDIR /home/app/
RUN npm install