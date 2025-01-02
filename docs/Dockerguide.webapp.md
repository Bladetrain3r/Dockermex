## Docker Deployment Guide

This section explains how to deploy the WAD Manager Web Application using Docker and Docker Compose.

### Prerequisites

- Docker installed on your system
- Docker Compose installed

### Configuration Files

#### 

docker-compose-webapp.yml

The 

docker-compose-webapp.yml

 file sets up the necessary Docker services for the application.

```yaml
services:
  nginx:
    image: nginx:latest
    volumes:
      - ./pwads:/pwads:ro
      - ./nginx_vol/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./html:/usr/share/nginx/html:ro
      - ./ssl/private.key:/etc/nginx/ssl/private.key:ro
      - ./ssl/fullchain.crt:/etc/nginx/ssl/fullchain.crt:ro
      - ./ssl/wads.key:/etc/nginx/ssl/wads.key:ro
      - ./ssl/wads.crt:/etc/nginx/ssl/wads.crt:ro
    ports:
      - "443:443"
      - "444:444"
    depends_on:
      - wad-upload-api
    entrypoint: |
      sh -c '
      apk add --no-cache apache2-utils
      if [ ! -f /etc/nginx/.htpasswd ]; then
        htpasswd -cb /etc/nginx/.htpasswd admin replaceme
      fi
      nginx -g "daemon off;" &
      wait
      '
    networks:
      wad-net:
        aliases: ["wads.zerofuchs.net", "master"]

  wad-upload-api:
    image: odamex_python:latest
    volumes:
      - ./iwads:/iwads:ro
      - ./pwads:/pwads
      - ./Python:/app:ro
      - ./service-configs:/service-configs
      - ./configs:/configs:ro
      - ./sqlite:/sqlite
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=development
    networks:
      wad-net:

networks:
  wad-net:
```

### Explanation

- **nginx**
  - **Image**: Uses the latest Nginx image.
  - **Volumes**: Mounts necessary directories and files into the container.
    - `./pwads:/pwads:ro`: Mounts the pwads directory as read-only.
    - `./nginx_vol/nginx.conf:/etc/nginx/conf.d/default.conf:ro`: Mounts the Nginx configuration file.
    - Other volumes mount SSL certificates and HTML files.
  - **Ports**: Exposes ports `443` and `444` on the host.
  - **depends_on**: Ensures the 

wad-upload-api

 service starts before Nginx.
  - **entrypoint**: Custom entrypoint script to set up basic authentication and start Nginx.
  - **networks**: Connects to the `wad-net` network with specified aliases.

- **wad-upload-api**
  - **Image**: Uses a custom Python image `odamex_python:latest`.
  - **Volumes**: Mounts application code and data directories.
    - 

iwads

, 

pwads

, 

Python

, 

service-configs

, 

configs

, 

sqlite


  - **Ports**: Exposes port `5000` for the API.
  - **environment**: Sets `FLASK_ENV` to `development`.
  - **networks**: Connects to the `wad-net` network.

- **networks**
  - Defines a custom network named `wad-net` for inter-service communication.

### Deployment Steps

1. **Build the Docker Images**

   Build the custom Python Docker image:

   ```bash
   docker build -t odamex_python:latest .
   ```

2. **Start the Services**

   Launch the services using Docker Compose:

   ```bash
   docker-compose -f docker-compose-webapp.yml up -d
   ```

3. **Verify the Deployment**

   - Access the web application at `https://yourdomain.com`.
   - Check running containers:

     ```bash
     docker ps
     ```

4. **Stop the Services**

   To stop the containers, run:

   ```bash
   docker-compose -f docker-compose-webapp.yml down
   ```

### Notes

- Replace placeholder values (e.g., `admin`, `replaceme`) with secure credentials.
- Ensure SSL certificates are correctly placed in the 

ssl

 directory.
- Update domain names and aliases to match your environment.