#!/bin/bash

oiwad=${IWAD:-"freedm.wad"}
oconfigfile=${CONFIGFILE:-"default.cfg"}

for item in iwads pwads config; do
echo "Checking ${item} folder."
ls /app/${item} | grep -i -e .wad -e .pk3 | grep -i -v .txt
echo ''
done

echo "Using config file: $oconfigfile"
test -e /app/config/$oconfigfile || echo "Config file not found"

echo "Using IWAD: $oiwad"
mkdir /home/ubuntu/.odamex
cp /app/odamex.wad /home/ubuntu/.odamex && \
cp /app/iwads/${oiwad} /home/ubuntu/.odamex && \
cp /app/config/${oconfigfile} /home/ubuntu/.odamex/odasrv.cfg

rm /app/iwads/*

pwads=$(ls /app/pwads | grep -i -e .wad -e .pk3 | grep -i -v .txt)
pwadparams=""
for file in $pwads; do
  pwadparams="$pwadparams -file /app/pwads/${file}"
done

cmd="/app/server/odasrv -iwad /app/iwads/${oiwad} -file /app/iwads/odamex.wad ${pwadparams}"
echo "Command: $cmd"

sleep 3

/app/server/odasrv -iwad "/app/iwads/${oiwad}" ${pwadparams}
#-file "/app/iwads/odamex.wad" \

