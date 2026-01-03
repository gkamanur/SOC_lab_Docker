#!/bin/bash

# SOC Detection Lab Startup Script

echo "Starting SOC Detection Lab (Minimal Profile)..."
echo "------------------------------------------------"

# Run docker compose with the minimal profile
docker compose -f docker-compose-minimal.yml up -d

echo ""
echo "Waiting for services to initialize..."
echo "------------------------------------------------"
echo "NOTE: Elasticsearch and Kibana may take 1-2 minutes to become fully ready."
echo ""

# Function to check if a port is open (basic check)
check_port() {
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/$1" 2>/dev/null
    return $?
}

echo "Access Information:"
echo "-------------------"
echo "1. Kibana (SIEM Dashboard):"
echo "   URL: http://localhost:5601"
echo "   Status: $(check_port 5601 && echo 'listening' || echo 'starting...')"
echo ""
echo "2. Elasticsearch:"
echo "   URL: http://localhost:9200"
echo "   Status: $(check_port 9200 && echo 'listening' || echo 'starting...')"
echo ""
echo "3. Ubuntu Web Server (Target):"
echo "   HTTP: http://localhost:8080"
echo "   SSH:  ssh user@localhost -p 2222"
echo ""
echo "4. Kali Attacker:"
echo "   Access: docker exec -it soc-kali-attacker-mini /bin/bash"
echo ""
echo "------------------------------------------------"
echo "To stop the lab, run: ./stop_soc_lab.sh"
echo "------------------------------------------------"
