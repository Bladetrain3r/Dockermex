#!/bin/bash
git reset --hard
git pull
sed -i 's/Hells Keep/Hells Keep - Africa/g' ./configs/*
docker-compose -f docker-compose-production.yml down
docker-compose -f docker-compose-production.yml up