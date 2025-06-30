# WAD Path Standardization

This document outlines the standardized approach for handling WAD file paths across all Dockermex services.

## Overview

All WAD paths are now consistently managed through environment variables defined in `.env`, ensuring:
- Consistent mounting across all services
- Easy path management from a central location
- Proper read-only access where appropriate
- Simplified deployment and maintenance

## Environment Variables

The following environment variables control WAD paths:

```env
IWAD_FOLDER=./iwads
PWAD_FOLDER=./pwads
ODAMEX_CONFIGS_PATH=./configs
```

**Important:** No spaces around the `=` sign in environment variables.

## Directory Structure

### IWAD Organization
```
./iwads/
├── freeware/          # Free IWADs (freedoom1.wad, freedoom2.wad, freedm.wad)
└── commercial/        # Commercial IWADs (doom.wad, doom2.wad, plutonia.wad, tnt.wad)
```

### PWAD Organization  
```
./pwads/
├── duel/              # Duel-specific PWADs
├── dm/                # Deathmatch PWADs
├── coop/              # Cooperative PWADs
├── ctf/               # Capture the Flag PWADs
├── scythe/            # Scythe series PWADs
├── misc/              # Miscellaneous PWADs
└── stub/              # Empty folder for configs with no PWADs
```

## Container Mount Points

All containers use consistent internal mount points:

- **IWADs**: `/app/iwads` (read-only)
- **PWADs**: `/app/pwads` (read-only)  
- **Configs**: `/app/config` (read-only)

## Service Configuration

### Docker Compose Services

All services now follow this volume mounting pattern:

```yaml
volumes:
  - ${IWAD_FOLDER}/freeware:/app/iwads:ro
  - ${PWAD_FOLDER}/duel:/app/pwads:ro
  - ${ODAMEX_CONFIGS_PATH}:/app/config:ro
```

### Web Application Services

The web application services mount the entire WAD directories to serve files:

```yaml
volumes:
  - ${IWAD_FOLDER}:/iwads:ro
  - ${PWAD_FOLDER}:/pwads:ro
```

## Updated Files

The following files have been standardized:

1. **`.env`** - Fixed spacing around environment variable assignments
2. **`docker-compose-odamex.yml`** - All services use environment variables consistently
3. **`docker-compose.yml.template`** - Template updated for new servers
4. **`runservers.py`** - Volume mounting logic simplified and standardized
5. **`docker-compose-webapp-modsec.yml`** - Already using environment variables correctly

## Benefits

### For Administrators
- **Centralized Configuration**: All paths managed in one `.env` file
- **Easy WAD Management**: Direct filesystem access for adding/removing WADs
- **Clear Organization**: Logical directory structure by game mode
- **Consistent Behavior**: All services behave identically

### For Containers
- **Predictable Paths**: All containers find WADs in the same locations
- **Proper Permissions**: Read-only mounts prevent accidental modifications
- **Network Connectivity**: All services connected to `wad-net` for inter-service communication
- **Resource Management**: Consistent CPU and memory limits

### For Development
- **Template System**: New servers automatically use standardized paths
- **Dynamic Volume Building**: Python script handles different WAD categories automatically
- **Environment-Driven**: Easy to change paths without modifying multiple files

## Migration Notes

If you have existing containers or different path structures:

1. Update your `.env` file with correct paths (no spaces around `=`)
2. Reorganize WAD files according to the new directory structure
3. Rebuild containers using the updated compose files
4. Test that all services can access their required WADs

## Future Considerations

- Consider implementing WAD validation checks
- Potential for automated WAD categorization
- Integration with WAD management tools
- Backup and sync strategies for WAD collections
