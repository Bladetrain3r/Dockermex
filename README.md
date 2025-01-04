# Initial Setup

- When cloning, be sure to use --recurse-submodules
- Build docker images
- Bring your own SSL certificates, iwads
- Dockerfile in route should build your base Odamex image
- Dockerfile in Dockermex_Api creates Python backend
- Frontend can be run from the standard nginx image - ensure mounts are correct 
- Use docker-compose and runservers.py to manage orchestration of persistent and temporary containers.