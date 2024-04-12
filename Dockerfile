# Create base image
FROM alpine:latest AS base

RUN apk update && apk add --no-cache apache-ant openjdk21-jre-headless bash

# Build project
FROM base AS build

ARG MARIADB_PASSWORD
ARG MARIADB_USER
ARG MARIADB_DATABASE
ARG MARIADB_HOSTNAME
ARG LOGIN_SERVER_HOSTNAME

WORKDIR /src

COPY . .

# Change some config paths to locations inside the container (the rest of the files will be stored on the host and then will be mounted as a volume)
# This is done so the original configs are not overwritten
# In order to change the following files, you need to rebuild the image: LoginServer.ini, Server.ini, ipconfig.xml
RUN sed -i \
	-e "s/.\/config\/LoginServer.ini/\/cfg\/LoginServer.ini/" \
	-e "s/.\/config\/Server.ini/\/cfg\/Server.ini/" \
	-e "s/.\/config\/ipconfig.xml/\/cfg\/ipconfig.xml/" /src/java/org/l2jmobius/Config.java

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
' >/src/dist/game/config/ipconfig.xml

# Update database/hostname settings
RUN sed -i -E \
	-e "s/\/\/\w+\/\w+\?/\/\/${MARIADB_HOSTNAME}\/${MARIADB_DATABASE}?/" \
	-e "s/^Login =.*$/Login = ${MARIADB_USER}/" \
	-e "s/^Password =.*$/Password = ${MARIADB_PASSWORD}/" \
	-e "s/^LoginHost =.*$/LoginHost = ${LOGIN_SERVER_HOSTNAME}/" /src/dist/game/config/Server.ini

RUN sed -i -E \
	-e "s/\/\/\w+\/\w+\?/\/\/${MARIADB_HOSTNAME}\/${MARIADB_DATABASE}?/" \
	-e "s/^Login =.*$/Login = ${MARIADB_USER}/" \
	-e "s/^Password =.*$/Password = ${MARIADB_PASSWORD}/" \
	-e "s/^LoginHostname =.*$/LoginHostname = ${LOGIN_SERVER_HOSTNAME}/" /src/dist/login/config/LoginServer.ini

# Build
RUN ant -f build.xml jar

RUN cp /build/dist/libs/*.jar /src/dist/libs/

# Keep only built files and persistent configs
FROM base

WORKDIR /opt/l2

# Copy built jar files
COPY --from=build /src/dist/libs/*.jar .

# Copy configs to custom config directory
RUN mkdir -p /cfg/
COPY --from=build /src/dist/game/config/ipconfig.xml /cfg/
COPY --from=build /src/dist/game/config/Server.ini /cfg/
COPY --from=build /src/dist/login/config/LoginServer.ini /cfg/
