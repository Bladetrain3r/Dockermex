#!/bin/bash
git reset --hard
git pull
chmod +x *.sh
sed -i 's/Hells Keep/Hells Keep - Brazil/g' ./configs/*
sed -i 's/localhost:8080/example.br:443/g' ./configs/*
docker-compose -f docker-compose-production.yml down
docker-compose -f docker-compose-production.yml up
