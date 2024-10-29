#!/bin/bash
git reset --hard
git pull
sed -i 's/Hells Keep/Hells Keep - Africa/g' ./configs/*
sed -i 's/localhost:8080/odamex.zerofuchs.co.za:8080/g' ./configs/*
docker-compose -f docker-compose-production.yml down
docker-compose -f docker-compose-production.yml up