#!/bin/bash

oiwad=${IWAD:-"freedm.wad"}
oconfigfile=${CONFIGFILE:-"default.cfg"}
odaport=${ODAPORT:-10667}

for item in iwads pwads config; do
echo "Checking ${item} folder."
ls /app/${item} | grep -i -e .wad -e .pk3 | grep -i -v .txt
echo ''
done

echo "Using config file: $oconfigfile"
test -e /app/config/$oconfigfile || echo "Config file not found"

echo "Using IWAD: $oiwad"
mkdir /home/odamex/.odamex
cp /app/odamex.wad /home/odamex/.odamex && \
cp /app/iwads/${oiwad} /home/odamex/.odamex && \
cp /app/config/${oconfigfile} /home/odamex/.odamex/odasrv.cfg

pwads=$(ls /app/pwads | grep -i -e .wad -e .pk3 | grep -i -v .txt)
pwadparams=""
for file in $pwads; do
  pwadparams="$pwadparams -file /app/pwads/${file}"
done

cmd="/app/server/odasrv -iwad /app/iwads/${oiwad} -file /app/iwads/odamex.wad ${pwadparams}"
echo "Command: $cmd"

/app/server/odasrv -iwad "/app/iwads/${oiwad}" ${pwadparams} -port ${odaport}
#-file "/app/iwads/odamex.wad" \

