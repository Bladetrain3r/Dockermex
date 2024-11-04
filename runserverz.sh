#!/bin/bash

# Default values
CONFIG_FILE=${CONFIGFILE:-"server.cfg"}
IWAD=${IWAD:-"DOOM2.WAD"}
PWAD=${PWAD:-""}
PORT=${ZANDROPORT:-10666}

# Base command
CMD="/app/server/zandronum-server"

# Add config if exists
if [ -f "/app/config/$CONFIG_FILE" ]; then
    CMD="$CMD +exec /app/config/$CONFIG_FILE"
fi

# Add IWAD
if [ -f "/app/iwads/$IWAD" ]; then
    CMD="$CMD -iwad /app/iwads/$IWAD"
else
    echo "Error: IWAD $IWAD not found!"
    exit 1
fi

# Add PWAD if specified
if [ ! -z "$PWAD" ] && [ -f "/app/pwads/$PWAD" ]; then
    CMD="$CMD -file /app/pwads/$PWAD"
fi

# Add port
CMD="$CMD +port $PORT"

# Additional Zandronum-specific settings
CMD="$CMD +sv_updatemaster 1"  # Update master server
CMD="$CMD +sv_broadcastport $((PORT+1))"  # Broadcast port
CMD="$CMD +sv_pure 1"  # Enable pure server mode
CMD="$CMD +sv_hostname $HOSTNAME"  # Set server name

echo "Starting Zandronum server with command: $CMD"
exec $CMD