FROM node:5
MAINTAINER Octoblu, Inc. <docker@octoblu.com>

EXPOSE 5683/udp

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json /usr/src/app/
RUN npm -s install --production
COPY . /usr/src/app/

CMD [ "node", "command.js" ]
