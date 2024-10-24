#!/bin/bash
# Export non-default environment variables
echo "Iwads:"
oconfigfile=${CONFIGFILE:-"default.conf"}
echo "Using config file: $oconfigfile"
test -e /app/config/$oconfigfile || echo "Config file not found"
sed -i 's/\r/\n/g' /app/config/$oconfigfile
source /app/config/$oconfigfile || echo "Failed to load from config file."

echo "Using IWAD: $oiwad"
oiwad=$(echo "$oiwad" | tr -d '\r')
mkdir /home/ubuntu/.odamex
cp /app/iwads/odamex.wad /home/ubuntu/.odamex && cp /app/iwads/${oiwad} /home/ubuntu/.odamex
for item in $(ls /app/iwads | grep -v ${oiwad}); do rm /app/iwads/${item}; done
# Will include all wads in the folder
pwads=$(ls /app/pwads | grep -i -e .wad -e .pk3 | grep -i -v .txt)
echo "pwads: ${pwads}"

gamemodes=("coop" "deathmatch" "tdm" "ctf")

# Function to get the index of a value in an array
get_index() {
  local value=$1
  shift
  local array=("$@")
  for i in "${!array[@]}"; do
    if [ "${array[$i]}" = "$value" ]; then
      echo $i
      return
    fi
  done
  echo -1
}

# Get the index of the gamemode
ogamemode=$(echo "$ogamemode" | tr -d '\r')
gamemode_flag=$(get_index "$ogamemode" "${gamemodes[@]}")

# Check if the gamemode is valid
if [ "$gamemode_flag" -eq -1 ]; then
  echo "Invalid gamemode: $ogamemode"
  exit 1
fi

echo "Using gamemode: $ogamemode (flag: $gamemode_flag)"

pwadparams=""
for file in $pwads; do
  echo "/app/pwads/${file}"
  pwadparams="$pwadparams -file /app/pwads/${file}"
done

cmd="/app/server/odasrv -iwad /app/iwads/${oiwad} -file /app/iwads/odamex.wad ${pwadparams}"
echo "Command: $cmd"

sleep 3

/app/server/odasrv -iwad "/app/iwads/${oiwad}" \
-file "/app/iwads/odamex.wad" \
${pwadparams} \
-port $oport \
+g_lives $olives \
+sv_teamsinplay $oteamsinplay \
+g_sides $osides \
-skill $oskill \
+sv_shufflemaplist $oshufflemaplist \
+sv_gametype $gamemode_flag \
+map ${ostartmap} \
+set sv_upnp 0 \
+join_password $ojoin_password \
+rcon_password $orcon_password \
+sv_email $oemail \
+sv_hostname $ohostname \
+sv_maxclients $omaxclients \
+sv_maxplayers $omaxplayers \
+sv_motd "Buggrit." \
+sv_usemasters $ousemasters