#!/bin/bash
git reset --hard
git pull
chmod +x *.sh
sed -i 's/Hells Keep/Hells Keep - Africa/g' ./configs/*
sed -i 's/localhost:8080/example.co.za:443/g' ./configs/*
docker-compose -f docker-compose-personal.yml down
docker-compose -f docker-compose-personal.yml up