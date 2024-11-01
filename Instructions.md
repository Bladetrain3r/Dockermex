# Odamex Server Manager and Wadserver Webapp

This repository contains scripts and configurations for managing Odamex servers and running the Wadserver web application.

## Prerequisites

- Docker
- Docker Compose
- Python 3.x

## Repository Structure

- `Server_Manager.py`: Script to manage Docker services for Odamex servers.
- `docker-compose-webapp.yml`: Docker Compose file to run the Wadserver web application.
- `configs/`: Directory containing configuration files for Odamex servers.
- `service-configs/`: Directory containing JSON configuration files for Docker services.

## Server Manager

The `Server_Manager.py` script provides functions to spin up and tear down Docker services based on JSON configuration files.

### Functions

- `docker_spinup()`: Spins up Docker services for each JSON configuration file in the `service-configs` directory.
- `docker_teardown()`: Tears down Docker services for each JSON configuration file in the `service-configs` directory.
- `create_docker_service(config_name)`: Creates and runs a new Docker service based on the specified JSON configuration file.
- `stop_docker_service(config_name)`: Stops and removes a Docker service based on the specified JSON configuration file.

### Usage

1. **Spin Up Docker Services:**

   ```sh
   python Server_Manager.py
   ```

- This will start Docker services for each JSON configuration file in the service-configs directory.

#### Tear Down Docker Services:

The script will automatically tear down the Docker services after 60 seconds. You can modify the sleep duration as needed.

## Wadserver Webapp
The wadserver web application is managed using Docker Compose.

### Running the Webapp
Build and Run the Docker Container:
```
docker-compose -f docker-compose-webapp.yml up -d
```
This will build and start the Docker container for the Wadserver web application.

### Access the Webapp:

Open your web browser and navigate to http://localhost:8080 to access the Wadserver web application.

## Customization
You can customize the server configurations by modifying the JSON files in the service-configs directory and the configuration files in the configs directory.

## Notes
Ensure that Docker and Docker Compose are installed and running on your system.

The Server_Manager.py script uses the Docker Python SDK to manage Docker services. Make sure the SDK is installed: