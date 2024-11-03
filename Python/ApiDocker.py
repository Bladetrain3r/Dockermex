import docker
import ApiUtils
import json
import os

# List of all the containers as json
def list_containers():
    client = docker.from_env()
    containers = client.containers.list()
    container_json = {}
    for container in containers:
        container_json[container.name] = container.attrs
    return json.dumps(container_json)