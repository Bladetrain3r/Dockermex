Sure, here is a README in GitHub Markdown format:

# Odamex Docker Setup

This repository contains the Docker setup for running an Odamex server. The setup includes building the server from source and running it with custom IWADs and PWADs.

NOTE: This does not compile odamex.wad, until that's working please obtain a copy from an Odamex release build.

## Repository Structure

- Dockerfile
- runserver.sh
- README
- configs
- - default.conf
- - doom2.conf
- - doom2dm.conf
- iwads/
- - doom.wad
- - DOOM2.WAD
- - freedoom1.wad
- - freedoom2.wad
- - odamex.wad
- pwads/
- - example.wad

runserver.sh

## Dockerfile

The `Dockerfile` is divided into two stages: build and runtime.

### Odamex Build Stage

The build stage clones the Odamex repository, installs necessary dependencies, and builds the `odasrv` server.

### FreeDoom Build

This stage only applies to Dockerfile.Freedoom, and will download + compile a copy of Freedoom.
I recommend using a precompiled binary and Dockerfile instead as this is likely not compatible with the copy clients will have, and will take extra space.

### Runtime Stage

The runtime stage sets up the environment for running the Odamex server, including copying IWADs, PWADs, and the `runserver.sh` script.

## runserver.sh

The `runserver.sh` script sets up the server environment, copies necessary files, and starts the Odamex server with the specified configuration.

## How to Build and Run

1. **Build the Docker Image:**

   ```sh
   docker build -t odamex-server -f Dockerfile .
   ```

   ```sh
   # Freedoom. Copy WAD out of final container as it will not match the hashsums of pre-existing binaries.
   docker build -t odamex-server -f Dockerfile.Freedoom .
   ```
   

2. **Run the Docker Container, set CONFIGFILE environment to change config:**

   ```sh
   docker run -d -e CONFIGFILE="doom2.conf" -p 10666:10666/udp --name odamex-server odamex-server
   ```

## Configuration

You can customize the server configuration by modifying the `runserver.sh` script and the IWADs/PWADs in the respective directories.
Specify IWAD and game mode at launch time using the environment variables `GAMEMODE` and `IWAD`

This Docker setup also includes compiling Freedoom and Deutex, both under the BSD license. Freedoom is a free content port of DOOM, while Deutex provides additional free content for enhanced gameplay.

For detailed instructions on building these components, please refer to their respective repositories:

- [Freedoom GitHub](https://github.com/freedoom/freedoom)
- [Deutex GitHub](https://github.com/deutex/deutex)

Please note that the checksum of the compiled freedoom WADs will differ from public stable builds and you will need to distribute them.
To copy it out to a local directory, run the container (note the tag) and run docker cp:
```sh
docker cp <CONTAINER_NAME>:/app/iwads/freedm.wad .
```

This is entirely optional, not really advisable, and it's easier just to dump one of the official binaries in the iwads folder then build the usual container.
It's mostly something for interest or if you want to run a server EXTRA privately.

## License

This project is licensed under the  Unlicense. Use the contents of this repository at your own risk. 
