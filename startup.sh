#!/bin/bash
sudo apt update
# Install docker engine
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

WWWREGION=${wwwregion:-"africa"}

# Region specific changes
cp ./ssl/${WWWREGION}.private.key ./ssl/private.key
cp ./ssl/${WWWREGION}.fullchain.crt ./ssl/fullchain.crt

sed -i "s/Hells Keep/Hells Keep - ${WWWREGION}/g" ./configs/*
sed -i "s/http:\/\/localhost:8080/https:\/\/wads.zerofuchs.net:444\/iwads https:\/\/wads.zerofuchs.net:444\/pwads/g" ./configs/*

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

docker build -t odamex_python:latest -f Dockerfile.Python .
docker build -t odamex:latest -f Dockerfile .
docker build -t odamex_managed:latest -f Dockerfile.Nodamex.Managed .d

# docker compose -f docker-compose-tiny.yml up -d
# docker compose -f docker-compose-tiny.yml down

# pip install docker
# python Server_Manager.py

