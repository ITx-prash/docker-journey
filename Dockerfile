# Since ubuntu is a large image, we can use those images which has node preinstalled from docker hub

# Base Image
# FROM ubuntu 

# We are using node image which is based on alpine linux, which is a lightweight linux distribution, and it has node preinstalled, so we don't need to install node separately
FROM node:24-alpine3.23
WORKDIR /home/app/

# COPY package.json  package.json
# COPY package-lock.json package-lock.json
COPY package*.json .

RUN npm install

# We don't need to install node separately because it's already installed in the base image, but if we were using ubuntu as base image, we would need to install node separately, and the commands would be like this:

# RUN apt update
# RUN apt install -y curl
# RUN curl -sL https://deb.nodesource.com/setup_24.x -o /tmp/nodesource_setup.sh
# RUN bash /tmp/nodesource_setup.sh
# RUN apt install -y nodejs

# Copying the source code to docker
COPY index.js  index.js

#just for doc purposes, but not just directly expose this port on host unless with -P flag 
EXPOSE 8000
# We can also specify what to run when the container starts
CMD ["npm","start"]