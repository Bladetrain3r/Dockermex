#!/bin/bash

oiwad=${IWAD:-"freedm.wad"}
oconfigfile=${CONFIGFILE:-"default.cfg"}
odaport=${ODAPORT:-10667}

for item in iwads pwads config; do
echo "Checking ${item} folder."
ls /app/${item} | grep -i -e .wad -e .pk3 | grep -i -v .txt
echo ''
done

doom1mapstring="E1M1 E1M2 E1M3 E1M4 E1M5 E1M6 E1M7 E1M8 E1M9 E2M1 E2M2 E2M3 E2M4 E2M5 E2M6 E2M7 E2M8 E2M9 E3M1 E3M2 E3M3 E3M4 E3M5 E3M6 E3M7 E3M8 E3M9 E4M1 E4M2 E4M3 E4M4 E4M5 E4M6 E4M7 E4M8 E4M9"
doom2mapstring="MAP01 MAP02 MAP03 MAP04 MAP05 MAP06 MAP07 MAP08 MAP09 MAP10 MAP11 MAP12 MAP13 MAP14 MAP15 MAP16 MAP17 MAP18 MAP19 MAP20 MAP21 MAP22 MAP23 MAP24 MAP25 MAP26 MAP27 MAP28 MAP29 MAP30 MAP31 MAP32"

echo "Using config file: $oconfigfile"
test -e /app/config/$oconfigfile || echo "Config file not found"

echo "Using IWAD: $oiwad"
mkdir /home/odamex/.odamex
cp /app/iwads/odamex.wad /home/odamex/.odamex && \
cp /app/iwads/${oiwad} /home/odamex/.odamex && \
cp /app/config/${oconfigfile} /home/odamex/.odamex/odasrv.cfg

if ! grep -q "coop" /app/config/${oconfigfile}; then
  maplist=""
  if [[ "$oiwad" == "doom.wad" || "$oiwad" == "freedoom1.wad" ]]; then
    mapstring=${doom1mapstring}
  else
    mapstring=${doom2mapstring}
  fi
  echo "Map string set to: $mapstring"
  for item in ${mapstring}; do
    maplist="${maplist} +addmap ${item}"
  done
  echo $maplist
fi

if [[ "$oconfigfile" == "coop-nuts.cfg"  ]]; then
  maplist="+addmap map01 nuts.wad"
elif [[ "$oconfigfile" == "coop-nuts.cfg"  ]]; then
  maplist="+addmap map01 DVII-1i.wad"
fi

pwads=$(ls /app/pwads | grep -i -e .wad -e .pk3 | grep -i -v .txt)
pwadparams=""
for file in $pwads; do
  pwadparams="$pwadparams -file /app/pwads/${file}"
done

cmd="/app/server/odasrv -iwad "/app/iwads/${oiwad}" ${pwadparams} -port ${odaport} ${maplist}"
echo "Command: $cmd"

/app/server/odasrv +set sv_waddownload 1 -iwad "/app/iwads/${oiwad}"${pwadparams} -port ${odaport}${maplist}

