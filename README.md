Sure, here is a README in GitHub Markdown format:

```markdown
# Odamex Docker Setup

This repository contains the Docker setup for running an Odamex server. The setup includes building the server from source and running it with custom IWADs and PWADs.

NOTE: This does not compile odamex.wad, until that's working please obtain a copy from an Odamex release build.

## Repository Structure

```
.
├── Dockerfile
├── iwads/
│   ├── doom.wad
│   ├── DOOM2.WAD
│   ├── freedoom1.wad
│   ├── freedoom2.wad
│   └── odamex.wad
├── pwads/
│   └── example.wad
├── 

runserver.sh

```

## Dockerfile

The `Dockerfile` is divided into two stages: build and runtime.

### Build Stage

The build stage clones the Odamex repository, installs necessary dependencies, and builds the `odasrv` server.

```dockerfile
FROM ubuntu:latest AS builder
WORKDIR /app
RUN apt update && apt install -y g++ cmake git libfltk1.3-dev libsdl2-dev libsdl2-mixer-dev libcurl4-openssl-dev libpng-dev libjsoncpp-dev zlib1g-dev libportmidi-dev libprotobuf-dev
RUN git clone https://github.com/odamex/odamex.git --recurse-submodules && mkdir build
WORKDIR /app/odamex/build
RUN cmake .. && make odasrv
```

### Runtime Stage

The runtime stage sets up the environment for running the Odamex server, including copying IWADs, PWADs, and the `runserver.sh` script.

```dockerfile
FROM ubuntu:latest AS server
WORKDIR /app
COPY --from=builder /app/odamex/build /app
COPY iwads /app/iwads
COPY pwads /app/pwads
COPY 

runserver.sh

 /app
USER ubuntu
ENTRYPOINT ["/usr/bin/bash", "/app/runserver.sh"]
EXPOSE 10666/udp
```

## runserver.sh

The `runserver.sh` script sets up the server environment, copies necessary files, and starts the Odamex server with the specified configuration.

```sh
#!/bin/bash
iwad=${IWAD:-"doom.wad"}
echo "Using IWAD: $iwad"
ls /app/iwads
mkdir /home/ubuntu/.odamex
cp /app/iwads/odamex.wad /home/ubuntu/.odamex && cp /app/iwads/$iwad /home/ubuntu/.odamex
pwads=$(ls /app/pwads)
echo "pwads: ${pwads}"
gamemodes=("coop" "deathmatch" "tdm" "ctf")
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
gamemode=${GAMEMODE:-"deathmatch"}
gamemode_flag=$(get_index "$gamemode" "${gamemodes[@]}")
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
+map "MAP01" "MAP02" "MAP03" \
+set sv_upnp 0 \
+join_password "" \
+rcon_password "" \
+sv_email "" \
+sv_hostname "Dockermex" \
+sv_maxclients 16 \
+sv_maxplayers 8 \
+sv_website "" \
+sv_motd "Welcome to the dungeon, marines." \
+sv_usemasters 0
```

## How to Build and Run

1. **Build the Docker Image:**

   ```sh
   docker build -t odamex-server .
   ```

2. **Run the Docker Container:**

   ```sh
   docker run -d -p 10666:10666/udp --name odamex-server odamex-server
   ```

## Configuration

You can customize the server configuration by modifying the `runserver.sh` script and the IWADs/PWADs in the respective directories.
Specify IWAD and game mode at launch time using the environment variables `GAMEMODE` and `IWAD`

## License

This project is licensed under the MIT License.
```

Feel free to customize the README further based on your specific needs.