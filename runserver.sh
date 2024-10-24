#!/bin/bash
iwad=${IWAD:-"doom.wad"}
echo "Using IWAD: $iwad"
ls /app/iwads
mkdir /home/ubuntu/.odamex
cp /app/iwads/odamex.wad /home/ubuntu/.odamex && cp /app/iwads/$iwad /home/ubuntu/.odamex
# Will include all wads in the folder
pwads=$(ls /app/pwads | grep -i -e .wad -e .pk3)
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
  echo -1  # Return -1 if the value is not found
}

# Get the gamemode from the environment variable or use the default
gamemode=${GAMEMODE:-"deathmatch"}

# Get the index of the gamemode
gamemode_flag=$(get_index "$gamemode" "${gamemodes[@]}")

# Check if the gamemode is valid
if [ "$gamemode_flag" -eq -1 ]; then
  echo "Invalid gamemode: $gamemode"
  exit 1
fi

echo "Using gamemode: $gamemode (flag: $gamemode_flag)"

pwadparams=""
for file in $pwads; do
  echo "/app/pwads/${file}"
  pwadparams="$pwadparams -file /app/pwads/${file}"
done

cmd="/app/server/odasrv -iwad /app/iwads/${iwad} -file /app/iwads/odamex.wad ${pwadparams}"
echo "Command: $cmd"

/app/server/odasrv -iwad "/app/iwads/${iwad}" \
-file "/app/iwads/odamex.wad" \
${pwadparams} \
-port 10666 \
+g_lives 0 \
+sv_teamsinplay 2 \
+g_sides 0 \
-skill 4 \
+sv_shufflemaplist 0 \
+sv_gametype $gamemode_flag \
+map "E1M1" \
+set sv_upnp 0 \
+join_password "" \
+rcon_password "" \
+sv_email "" \
+sv_hostname "Dockermex" \
+sv_maxclients 16 \
+sv_maxplayers 8 \
+sv_motd "Welcome to the dungeon, marines." \
+sv_usemasters 0