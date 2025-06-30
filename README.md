# Dockermex
## Version: 0.3
## State: Alpha

## What is it?

A full stack webapp being built with the explicit purpose of easily hosting DOOM servers with custom WADS or with different server configs.
Currently focused on Odamex as the source port of choice.

## Goal and Purpose
My goal with this is to make it easy for people to spin up a server with a mod set, so folk can play co-op or deathmatch on a dime.
The purpose is to provide a platform for one or multiple people to manage multiple Odamex servers and their provisioning with a few clicks. No need to fiddle with configs.
Eventually, want to extend this to multiple multiplayer source ports, but Odamex is what I work with and it's a solid software package for the purpose.

Who is this for?
- Mappers who want to test their map or mmapset with a group of people, or specifically want to test co-op maps.
- People who just want to spin up a server and play with friends or clan mates without a whole lot of time getting server and client stuff working.
- People who want to host DOOM multiplayer for any given reason.

## Current Features
- Upload and manage WAD files through a session based web interface
- Create game server configurations for particular combinations of iwad, pwad and match type.
- Built-in ModSecurity WAF for protection
- User authentication and role-based access
- Support for Freedoom and commercial IWADs
- WAD download mirror built in
- Commercial IWADs blocked from upload or download

## Design Aspirations

*A Declarative Webapp*
The user declares what they want, the application handles making it so.

*Single Purpose Microservices*
Avoid bundling logic between modules of code.
Individual component failures may cause degradation but failure will be isolated.

*Compose on a Dime*
Docker based building blocks mean you can test one part or the whole stack at once.

*Manage Configuration Cleanly*
Nothing hardcoded that matters
And doublecheck if it matters
Keep configs as single source of truth for environments, and make them easily sourcable from secret stores.

*Tough Nut*
Out of box security config
Least Privilege checked
Straightforward auth, solid barriers

*Dev Friendly*
If I take a break for 6 months, I want to be able to understand what I'm looking at.
Easy testing locally
Easy setup on the remote host

*One Man Project*
While many people work on the many third party tools used by Dockermex, the project itself is just me right now.
With that in mind, the aspiration is to:
- Keep scope creep in check
- Minimise complexity
- Overengineer only where needed
- Make the code accessible for anyone interested in forking or contributing.

## Initial Setup

1) Git clone this project using the --recurse-submodules command to sync the API and Frontend code.
2) Install dependencies (see below)
3) Create a envfile (.env) from the template and point to the locations of your WADs
4) To run just the API and Webapp, run *docker compose -f docker-compose-webapp-modsec.yml*
5) To run some Odamex servers, refer to docker-compose-odamex.yml for examples. These are for testing the Odamex image and you only need the webapp compose file.

Once you've confirmed both the webapp and the odamex servers run, you can try running **runservers.py** - this is the server manager app although it is due for a refactor.
Might need to update the image tags.

### After Setup
1. Login with admin credentials
2. Upload a WAD 
3. Create a server configuration
4. Share the server address with friends (if on an accessible network)
5. Prove yourself lord of the frags.

### Dependencies
On the host that will be running Dockermex:
docker
docker compose (plugin)
Python ~3.10
docker modules for Python

Everything else should happen within the containers or be included as part of the submodules.

## Architecture Overview
- **Frontend**: Nginx + ModSecurity (serves web UI, handles SSL)
- **API**: Python Flask (manages configurations and containers)
- **Database**: SQLite (user management, WAD registry)
- **Game Servers**: Odamex in Docker containers (the actual DOOM servers)

## Support
- GitHub Issues for bugs
- Doomworld forums (zerofuchs)


