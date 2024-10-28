#!/bin/bash
git reset --hard
git pull
sed -i 's/Hells Keep/Hells Keep - Brazil/g' ./configs/*
docker-compose -f docker-compose-production.yml restart