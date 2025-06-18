# Initial Setup

- When cloning, be sure to use --recurse-submodules
- Run docker compose -f docker-compose-webapp-modsec.yml for the core API and frontend
- This will let you upload WADS and specify launch configs
- Bring your own SSL certificates, iwads
- docker-compose-odamex is an example of how to build the actual DOOM servers
- Runserver.py runs on the host OS and orchestrates based on the webapp - very rough.

