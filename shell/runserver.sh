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
cp /app/iwads/freeware/odamex.wad /home/odamex/.odamex && \
cp /app/iwads/${oiwad} /home/odamex/.odamex && \
cp /app/config/${oconfigfile} /home/odamex/.odamex/odasrv.cfg

if grep -v "coop" /app/config/${oconfigfile}; then
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

# Get list of IWADs to exclude from pwads
iwads=$(ls /app/iwads 2>/dev/null | grep -i -e .wad -e .pk3 | grep -i -v .txt)
echo "IWADs found: $iwads"

# Get pwads and filter out any that match IWAD names
all_pwads=$(ls /app/pwads 2>/dev/null | grep -i -e .wad -e .pk3 | grep -i -v .txt)
pwads=""
for file in $all_pwads; do
  is_iwad=false
  for iwad in $iwads; do
    if [ "$file" = "$iwad" ]; then
      is_iwad=true
      echo "Skipping $file (found in iwads folder)"
      break
    fi
  done
  if [ "$is_iwad" = false ]; then
    pwads="$pwads $file"
  fi
done

pwadparams=""
for file in $pwads; do
  pwadparams="$pwadparams $file"
done
echo "PWADs to load: $pwads"

# Copy PWADs to odamex directory for easier access
if [ -n "$pwadparams" ]; then
  echo "Copying PWADs to odamex directory..."
  for file in $pwads; do
    cp "/app/pwads/${file}" /home/odamex/.odamex/
  done
fi

# Build the complete command
if [ -n "$pwadparams" ]; then
  cmd="/app/server/odasrv -iwad /home/odamex/.odamex/${oiwad} -file ${pwadparams} -port ${odaport}${maplist}"
else
  cmd="/app/server/odasrv -iwad /home/odamex/.odamex/${oiwad} -port ${odaport}${maplist}"
fi
echo "Command: $cmd"

# Execute the command
eval $cmd -logfile /var/log/odamex/odasrv_${odaport}.log &

sleep 72000
exit 0

