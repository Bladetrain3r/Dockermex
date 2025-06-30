import json
import os
from time import sleep
import docker
from docker.errors import NotFound

BASE_PORT = 10564
MAX_PORT = 10576

def find_available_port():
    """Find an available port in the defined range."""
    client = docker.from_env()
    for port in range(BASE_PORT, MAX_PORT + 1):
        port_in_use = False
        for container in client.containers.list():
            ports = container.attrs['NetworkSettings']['Ports']
            # print(f"Checking container: {container.name}, Ports: {ports}")
            for binding in ports.values():
                if binding:
                    # print(f"Checking binding: {binding}")
                    if any(port == int(b['HostPort']) for b in binding):
                        print(f"Port {port} is in use by container {container.name}")
                        port_in_use = True
                        break
            if port_in_use:
                break
        if not port_in_use:
            print(f"Port {port} is available")
            return port
    return False


def create_docker_service(config_name):
    """Create and run a new Docker service based on the configuration JSON."""
    client = docker.from_env()
    strip_config = config_name.strip('.json')

    # Load configuration JSON
    with open(f'./service-configs/{config_name}', encoding='utf-8') as f:
        config = json.load(f)

    # Get available port
    port = find_available_port()

    # Environment and volume settings
    env_vars = {
        'CONFIGFILE': config["configFile"],
        'IWAD': config["iwadFile"],
        'ODAPORT': port
    }
    config_file = config.get("configFile")
    config_mount = os.path.abspath(f'./configs/{config_file}') if config_file else os.path.abspath('./configs/default.cfg')
    pwad_file = config.get("pwadFile")
    pwad_mount = os.path.abspath(f'./pwads/{pwad_file}') if pwad_file else None
    iwad_file = config.get("iwadFile")
    if iwad_file:
        iwad_mount = os.path.abspath(f'./iwads/commercial/{iwad_file}')
        if not os.path.exists(iwad_mount):
            iwad_mount = os.path.abspath(f'./iwads/freeware/{iwad_file}')
            if not os.path.exists(iwad_mount):
                iwad_mount = os.path.abspath('./iwads/freeware/freedoom2.wad')
    else:
        iwad_mount = os.path.abspath('./iwads/freeware/freedoom2.wad')

    odamount = os.path.abspath('./iwads/odamex.wad')

    volumes = {
        config_mount: {'bind': f'/app/config/{config_file}', 'mode': 'ro'},
        pwad_mount: {'bind': f'/app/pwads/{pwad_file}', 'mode': 'ro'},
        iwad_mount: {'bind': f'/app/iwads/{iwad_file}', 'mode': 'ro'},
        odamount: {'bind': '/app/iwads/odamex.wad', 'mode': 'ro'},
    }

    if not port:
        print("No available ports found")
        return

    # Run the container
    container = client.containers.run(
        image="odamex_managed:latest",
        name=f"odamex_{strip_config}",
        ports={f'{port}/udp':port},
        environment=env_vars,
        volumes=volumes,
        restart_policy={"Name": "unless-stopped"},
        detach=True,
        mem_limit='64m',
        # 1cpu = 1,000,000,000 nano_cpus
        nano_cpus=250000000
    )

    print(f"Container {container.name} is running on port {port}\n")
    return container

def stop_docker_service(config_name):
    """Stop and remove a Docker service based on the configuration JSON."""
    client = docker.from_env()
    strip_config = config_name.strip('.json')

    try:
        container = client.containers.get(f"odamex_{strip_config}")
    except NotFound:
        print(f"Container odamex_{strip_config} not found")
        return False

    container.stop()
    container.remove()
    print(f"Container odamex_{strip_config} stopped and removed")
    return True

def docker_spinup():
    """Spin up all the containers in the service-configs directory."""
    for item in os.listdir('./service-configs'):
        if item.endswith('.json') and not item.endswith('.expired') and not item.startswith('users'):
            # Check if the container is already running
            client = docker.from_env()
            strip_config = item.strip('.json')
            try:
                container = client.containers.get(f"odamex_{strip_config}")
                print(f"Container {container.name} already running")
            except NotFound:
                print(f"Attempting to launch {strip_config}")
                sleep(1)
                create_docker_service(item)

def docker_teardown(expiries=False):
    """Stop and remove all the containers in the service-configs directory."""
    for item in os.listdir('./service-configs'):
        if item.endswith('.json'):
            if stop_docker_service(item):
                if not expiries:
                    continue
                if f'{item}.expired' in os.listdir("./service-configs"):
                    os.remove(f"./service-configs/{item}.expired")
                os.rename(f"./service-configs/{item}", f"./service-configs/{item}.expired")

if __name__ == "__main__":
    while True:
        try:
            print("Spinning Up Containers")
            docker_spinup()
            print("Sleeping for 24 hours")
            sleep(86400)
            #docker_teardown()
        except KeyboardInterrupt:
            docker_teardown()
            print("Test Complete")
            break
