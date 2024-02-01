#!/bin/bash

# Define the registry IP and port
REGISTRY="10.188.152.16:443"

# Path to Docker's daemon.json
DAEMON_JSON="/etc/docker/daemon.json"

# Check if daemon.json exists
if [ ! -f "$DAEMON_JSON" ]; then
    echo "{}" > "$DAEMON_JSON"
fi

# Add the registry to the insecure-registries list
jq --arg REGISTRY "$REGISTRY" '.["insecure-registries"] += [$REGISTRY]' "$DAEMON_JSON" > temp.json && mv temp.json "$DAEMON_JSON"
