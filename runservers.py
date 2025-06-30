import json
import os
from time import sleep
import docker
from docker.errors import NotFound
from dotenv import load_dotenv

# Load environment variables from .env file
# Note: Requires python-dotenv package: pip install python-dotenv
load_dotenv()

# Validate critical environment variables
def validate_environment():
    """Validate that required environment variables and paths exist."""
    iwad_folder = os.getenv('IWAD_FOLDER', './iwads')
    pwad_folder = os.getenv('PWAD_FOLDER', './pwads')
    
    if not os.path.exists(iwad_folder):
        print(f"Warning: IWAD folder '{iwad_folder}' does not exist")
    if not os.path.exists(pwad_folder):
        print(f"Warning: PWAD folder '{pwad_folder}' does not exist")
        
    # Only validate critical paths exist, don't auto-create
    
validate_environment()

BASE_PORT = int(os.getenv('ODAPORT', 10666))
MAX_PORT = BASE_PORT + 12  # Allow for 12 additional ports

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


def determine_pwad_category(config_name, config):
    """Determine PWAD category/subfolder based on config name and content."""
    # Extract category from config name pattern
    # Examples: dm-modern_freedm_.json -> dm, coop-modern_freedoom1_.json -> coop
    if 'dm' in config_name.lower():
        return 'dm'
    elif 'duel' in config_name.lower():
        return 'duel'
    elif 'coop' in config_name.lower():
        return 'coop'
    elif 'ctf' in config_name.lower():
        return 'ctf'
    
    # Check config file for hints
    config_file = config.get('configFile', '').lower()
    if 'dm' in config_file:
        return 'dm'
    elif 'duel' in config_file:
        return 'duel'
    elif 'coop' in config_file:
        return 'coop'
    elif 'ctf' in config_file:
        return 'ctf'
    
    # Default category
    return 'misc'


def build_volume_mounts(iwad_folder, pwad_folder, configs_path, 
                       iwad_subfolder, pwad_category, 
                       iwad_file, pwad_file, config_file):
    """Build Docker volume mounts based on environment paths and WAD categories."""
    volumes = {}
    
    # Config directory mount (mount entire config directory for consistency)
    config_dir_path = os.path.abspath(configs_path)
    volumes[config_dir_path] = {'bind': '/app/config', 'mode': 'ro'}
    
    # IWAD mount - mount the specific subfolder
    iwad_subfolder_path = os.path.abspath(os.path.join(iwad_folder, iwad_subfolder))
    if os.path.exists(iwad_subfolder_path):
        volumes[iwad_subfolder_path] = {'bind': '/app/iwads', 'mode': 'ro'}
    else:
        print(f"Warning: IWAD subfolder '{iwad_subfolder_path}' does not exist")
    
    # PWAD mount - always attempt to mount the category folder
    pwad_category_path = os.path.abspath(os.path.join(pwad_folder, pwad_category))
    if os.path.exists(pwad_category_path):
        volumes[pwad_category_path] = {'bind': '/app/pwads', 'mode': 'ro'}
    else:
        print(f"Warning: PWAD category folder '{pwad_category_path}' does not exist")
        # Mount an empty stub folder if it exists, otherwise don't mount PWADs
        stub_path = os.path.abspath(os.path.join(pwad_folder, 'stub'))
        if os.path.exists(stub_path):
            volumes[stub_path] = {'bind': '/app/pwads', 'mode': 'ro'}
    
    # Add startup script if it exists
    startup_script = os.path.abspath('./shell/runserver.sh')
    if os.path.exists(startup_script):
        volumes[startup_script] = {'bind': '/app/runserver.sh', 'mode': 'ro'}
    
    return volumes


def create_docker_service(config_name):
    """Create and run a new Docker service based on the configuration JSON."""
    client = docker.from_env()
    strip_config = config_name.strip('.json')

    # Load configuration JSON
    with open(f'./service-configs/{config_name}', encoding='utf-8') as f:
        config = json.load(f)

    # Get available port
    port = find_available_port()

    # Get paths from environment variables
    iwad_folder = os.getenv('IWAD_FOLDER', './iwads')
    pwad_folder = os.getenv('PWAD_FOLDER', './pwads')
    configs_path = os.getenv('ODAMEX_CONFIGS_PATH', './configs')
    
    # Resource limits from env
    cpu_limit = os.getenv('ODAMEX_CPU_LIMIT', '0.2')
    memory_limit = os.getenv('ODAMEX_MEMORY_LIMIT', '64M')

    # Environment variables for container
    env_vars = {
        'CONFIGFILE': config["configFile"],
        'IWAD': config["iwadFile"],
        'ODAPORT': port
    }
    
    # Determine WAD category/subfolder based on config
    iwad_file = config.get("iwadFile", "freedoom2.wad")
    pwad_file = config.get("pwadFile", "")
    config_file = config.get("configFile", "default.cfg")
    
    # Determine IWAD subfolder (commercial vs freeware)
    iwad_subfolder = "freeware"  # Default
    commercial_iwads = ["doom.wad", "doom2.wad", "plutonia.wad", "tnt.wad", "heretic.wad", "hexen.wad"]
    if iwad_file.lower() in [iw.lower() for iw in commercial_iwads]:
        iwad_subfolder = "commercial"
    
    # Determine PWAD category from config name or explicit mapping
    pwad_category = determine_pwad_category(config_name, config)
    
    # Build volume mounts using env-defined paths
    volumes = build_volume_mounts(
        iwad_folder, pwad_folder, configs_path,
        iwad_subfolder, pwad_category, 
        iwad_file, pwad_file, config_file
    )

    if not port:
        print("No available ports found")
        return

    # Convert CPU limit to nano_cpus (1 CPU = 1,000,000,000 nano_cpus)
    nano_cpus = int(float(cpu_limit) * 1_000_000_000)
    
    print(f"Creating container {strip_config} with:")
    print(f"  Port: {port}")
    print(f"  IWAD: {iwad_file} (from {iwad_subfolder})")
    print(f"  PWAD Category: {pwad_category}")
    print(f"  Config: {config_file}")
    print(f"  CPU Limit: {cpu_limit} ({nano_cpus} nano_cpus)")
    print(f"  Memory Limit: {memory_limit}")

    # Sanitize container name (replace problematic characters)
    container_name = f"odamex_{strip_config}".replace('-', '_')
    
    # Determine the correct network name
    networks = client.networks.list()
    wad_network = None
    
    # Look for dockermex_wad-net first, then fall back to wad-net
    for network in networks:
        if network.name == 'dockermex_wad-net':
            wad_network = network.name
            break
        elif 'wad-net' in network.name or network.name == 'wad-net':
            wad_network = network.name
    
    if not wad_network:
        print("Warning: No wad-net network found, using default bridge")
        wad_network = "bridge"
    
    print(f"  Using network: {wad_network}")
    print(f"  Container name: {container_name}")

    # Run the container
    container = client.containers.run(
        image="odamex:latest",  # Updated to match docker-compose
        name=container_name,
        ports={f'{port}/udp': port},
        environment=env_vars,
        volumes=volumes,
        restart_policy={"Name": "unless-stopped"},
        detach=True,
        mem_limit=memory_limit,
        nano_cpus=nano_cpus,
        network=wad_network,
    )

    print(f"Container {container.name} is running on port {port}\n")
    return container

def stop_docker_service(config_name):
    """Stop and remove a Docker service based on the configuration JSON."""
    client = docker.from_env()
    strip_config = config_name.strip('.json')
    container_name = f"odamex_{strip_config}".replace('-', '_')

    try:
        container = client.containers.get(container_name)
    except NotFound:
        print(f"Container {container_name} not found")
        return False

    try:
        # Stop with timeout
        container.stop(timeout=10)
        # Wait for stop to complete before removing
        container.wait()
        container.remove()
        print(f"Container {container_name} stopped and removed")
        return True
    except Exception as e:
        print(f"Error stopping/removing container {container_name}: {e}")
        # Try force removal if normal stop fails
        try:
            container.remove(force=True)
            print(f"Container {container_name} force removed")
            return True
        except Exception as e2:
            print(f"Failed to force remove container {container_name}: {e2}")
            return False

def docker_spinup():
    """Spin up all the containers in the service-configs directory."""
    for item in os.listdir('./service-configs'):
        if item.endswith('.json') and not item.endswith('.expired') and not item.startswith('users'):
            # Check if the container is already running
            client = docker.from_env()
            strip_config = item.strip('.json')
            try:
                container_name = f"odamex_{strip_config}".replace('-', '_')
                container = client.containers.get(container_name)
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