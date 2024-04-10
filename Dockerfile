# Create base image
FROM alpine:latest AS base

RUN apk update && apk add --no-cache apache-ant openjdk21-jre-headless bash

# Build project
FROM base AS build

WORKDIR /src

COPY . .

# build project
RUN ant -f build.xml jar

# copy built files
RUN cp /build/dist/libs/*.jar /src/dist/libs/

# Create new layer, we keep only built files and dependencies
FROM base

ARG MARIADB_PASSWORD
ARG MARIADB_USER
ARG MARIADB_DATABASE
ARG MARIADB_HOSTNAME
ARG LOGIN_SERVER_HOSTNAME

WORKDIR /dist

# Copy built files
COPY --from=build /src/dist .

# Create log directories
RUN mkdir -p /dist/game/log
RUN mkdir -p /dist/login/log

# Update configs with db creds/hostnames coming from .env through docker-compose
RUN sed -i -E \
	-e "s/\/\/\w+\/\w+\?/\/\/${MARIADB_HOSTNAME}\/${MARIADB_DATABASE}?/" \
	-e "s/^Login =.*$/Login = ${MARIADB_USER}/" \
	-e "s/^Password =.*$/Password = ${MARIADB_PASSWORD}/" \
	-e "s/^LoginHost =.*$/LoginHost = ${LOGIN_SERVER_HOSTNAME}/" /dist/game/config/Server.ini

RUN sed -i -E \
	-e "s/\/\/\w+\/\w+\?/\/\/${MARIADB_HOSTNAME}\/${MARIADB_DATABASE}?/" \
	-e "s/^Login =.*$/Login = ${MARIADB_USER}/" \
	-e "s/^Password =.*$/Password = ${MARIADB_PASSWORD}/" \
	-e "s/^LoginHostname =.*$/LoginHostname = ${LOGIN_SERVER_HOSTNAME}/" /dist/login/config/LoginServer.ini

# Add network config
RUN echo -e '\
<?xml version="1.0" encoding="UTF-8"?>\n\
<!-- Note: If file is named "ipconfig.xml" this data will be used as network configuration, otherwise server will configure it automatically! -->\n\
<!-- Externalhost here (Internet IP) or Localhost IP for local test -->\n\
<gameserver address="127.0.0.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../data/xsd/ipconfig.xsd">\n\
	<!-- Localhost here -->\n\
	<define subnet="127.0.0.0/8" address="127.0.0.1" />\n\
	<!-- Internalhosts here (LANs IPs) -->\n\
	<define subnet="192.168.1.0/24" address="192.168.1.2" />\n\
</gameserver>\n\
' >/dist/game/config/ipconfig.xml
