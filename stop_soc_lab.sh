#!/bin/bash

# SOC Detection Lab Shutdown Script

echo "Stopping SOC Detection Lab..."
echo "-----------------------------"

# Stop the containers
docker compose -f docker-compose-minimal.yml down

echo ""
echo "Lab stopped successfully."
