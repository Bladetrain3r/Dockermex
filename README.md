Sure, here is a README in GitHub Markdown format:

# Odamex Docker Setup

This repository contains the Docker setup for running an Odamex server. The setup includes building the server from source and running it with custom IWADs and PWADs.

NOTE: This does not compile odamex.wad, until that's working please obtain a copy from an Odamex release build.

## Repository Structure

├── Dockerfile
├── runserver.sh
├── README
├── iwads/
│   ├── doom.wad
│   ├── DOOM2.WAD
│   ├── freedoom1.wad
│   ├── freedoom2.wad
│   └── odamex.wad
├── pwads/
│   └── example.wad

runserver.sh

## Dockerfile

The `Dockerfile` is divided into two stages: build and runtime.

### Build Stage

The build stage clones the Odamex repository, installs necessary dependencies, and builds the `odasrv` server.

### Runtime Stage

The runtime stage sets up the environment for running the Odamex server, including copying IWADs, PWADs, and the `runserver.sh` script.

## runserver.sh

The `runserver.sh` script sets up the server environment, copies necessary files, and starts the Odamex server with the specified configuration.

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

This project is licensed under the  Unlicense. Use the contents of this repository at your own risk. 
