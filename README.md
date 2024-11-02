# Odamex Docker Setup

This repository contains the Docker setup for running an Odamex server. The setup includes building the server from source and running it with custom IWADs and PWADs.

## Prerequisites

### Installing Docker

Find instructions for Docker Desktop to run locally here: https://docs.docker.com/desktop/
To run Docker on a server, see here (and don't forget to install docker-compose): https://docs.docker.com/engine/install/ubuntu/


## Repository Structure

- `.gitignore`
- `africa.sh`
- `brazil.sh`
- `CONCEPT.md`
- `configs/`
- - `coop-doom.cfg`
- - ...
- `CREDITS/`
- - ...
- `docker-compose-files`
- `Dockerfiles`
- `Dockerfiles/`
- `GOALS.md`
- `html/`
- - `index.html`
- - `styles.css`
- `Instructions.md`
- `iwads/`
- - `commercial/`
- - `freeware/`
- `LICENSES/`
- `nginx_vol/`
- - `nginx.conf`
- `pwads/`
- `Python/`
- - `ApiUpload.py`
- - `requirements.txt`
- `README.md`
- `runserver.sh`
- `Server_Manager.py`
- `service-configs/`
- - `coop_freedoom2_SCYTHE.json`
- - ...
- `ssl/`
- `tests/`

runserver.sh

## Dockerfile

The `Dockerfile` is divided into two stages: build and runtime.

### Odamex Build Stage

The build stage clones the Odamex repository, installs necessary dependencies, and builds the `odasrv` server.

### FreeDoom Build

This stage only applies to Dockerfile.Freedoom, and will download from source and compile a copy of Freedoom.

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

## Docker Compose Files

This repository includes Docker Compose files to simplify the deployment of persistent services.

### docker-compose.yml

The `docker-compose.yml` file defines three services:

- **docker-compose-webapp** composes the core web frontend to test file upload and configuration management.
- **docker-compose-tiny** composes the webapp and a pair of servers for a sort of default setup.

Each service mounts the `iwads`, `pwads`, and `configs` directories from the host to the container, allowing for easy customization and configuration.

To start the services defined in `docker-compose.yml`, run:

```sh
docker-compose up -d
```

## The Webapp

The webapp consists of an nginx host serving a static page(s) as a frontend, with a Python Flask (gunicorn) API handling file operations, authentication and server monitoring.

### Customization

You can customize the server configurations by modifying the environment variables and volume mounts in the Compose files. For example, to change the IWAD or configuration file, update the `IWAD` and `CONFIGFILE` environment variables in the respective service definitions.

For more detailed information on the available configuration options, refer to the [Odamex Wiki](https://github.com/odamex/odamex/wiki/Console-Variables).

## Notes
- WADs compiled from source will have a unique checksum so will need to be provided to clients.

## Configuration

You can customize the server configuration by modifying or creating new conf files in the configs folder, and by placing IWADs/PWADs in the respective directories.
The sample configs included are from the Odamex repository. For in-depth information on these variables, visit https://github.com/odamex/odamex/wiki/Console-Variables
Specify configfile at launch time using the environment variable CONFIGFILE. Defaults to default.conf.

This Docker setup also includes compiling Freedoom and Deutex, both under the BSD license. Freedoom is a free content port of DOOM, while Deutex provides additional tools for handling and editing Doom files.

For detailed instructions on building individual components, please refer to their respective repositories:

- [Odamex Github](https://github.com/odamex/odamex.git)
- [Freedoom GitHub](https://github.com/freedoom/freedoom)
- [Deutex GitHub](https://github.com/Doom-Utils/deutex)

Please note that the checksum of the compiled freedoom WADs will differ from public stable builds and you will need to distribute them.
To copy it out to a local directory, run the container (note the tag) and run docker cp:
```sh
docker cp <CONTAINER_NAME>:/app/iwads/freedm.wad .
```

This is entirely optional, not really advisable, and it's easier just to dump one of the official binaries in the iwads folder then build the usual container.
It's mostly something for interest or if you want to run a server EXTRA privately.

## Licenses

This project is licensed under the  Unlicense. Use the contents of this repository at your own risk. 

Odamex is licensed under the [GNU GPL2 public license](https://github.com/odamex/odamex/blob/stable/LICENSE) 
Freedoom is licensed under [this license](https://github.com/freedoom/freedoom/blob/master/COPYING.adoc)
Deutex is licensed under a [GPL2 license with additional third party licenses](https://github.com/Doom-Utils/deutex/blob/master/LICENSE)

# Credits:
## [Odamex](https://github.com/odamex/odamex/blob/stable/MAINTAINERS)
## [FreeDoom](https://github.com/freedoom/freedoom/blob/master/CREDITS)
## [Deutex](https://github.com/Doom-Utils/deutex/blob/master/AUTHORS)
