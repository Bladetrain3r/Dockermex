# Initial Setup

- When cloning, be sure to use --recurse-submodules
- Build docker images
- Bring your own SSL certificates, iwads
- Dockerfile in root should build your base Odamex image
- Dockerfile in Dockermex_Api creates Python backend
- Frontend can be run from the standard nginx image - ensure mounts are correct 
- Use docker-compose and runservers.py to manage orchestration of persistent and temporary containers.

  # Dev Note:
  This is functional enough for personal use but I'm moving development into a private repo as part of a larger project for now.
  Feel free to fork or use for your own code but all third party licenses stay in effect, so be mindful of submodules.
  Use this code entirely at your own risk.
