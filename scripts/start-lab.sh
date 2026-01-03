#!/bin/bash

# SOC Detection Lab - Docker Deployment Start Script
# This script automates the deployment of the entire SOC lab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SOC Detection Lab - Docker Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker daemon is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Navigate to docker-deployment directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

echo -e "${GREEN}✓${NC} Docker installed and running"
echo ""

# Create necessary directories
echo -e "${YELLOW}Creating configuration directories...${NC}"
mkdir -p configs/{elasticsearch,logstash/pipeline,kibana,suricata,filebeat,wazuh}
mkdir -p dockerfiles
mkdir -p attack-scenarios
mkdir -p detection-rules
echo -e "${GREEN}✓${NC} Directories created"
echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cat > .env << 'EOF'
# Elastic Stack Configuration
ELASTIC_PASSWORD=changeme
ELASTIC_VERSION=8.11.0

# Wazuh Configuration
WAZUH_VERSION=4.7.0

# Network Configuration
SUBNET=172.20.0.0/16
EOF
    echo -e "${GREEN}✓${NC} .env file created"
else
    echo -e "${GREEN}✓${NC} .env file already exists"
fi
echo ""

# Create minimal config files
echo -e "${YELLOW}Creating minimal configuration files...${NC}"

# Elasticsearch config
cat > configs/elasticsearch/elasticsearch.yml << 'EOF'
cluster.name: soc-cluster
node.name: soc-es-node
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
EOF

# Logstash config
cat > configs/logstash/logstash.yml << 'EOF'
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: ["http://172.20.0.10:9200"]
xpack.monitoring.elasticsearch.username: "elastic"
xpack.monitoring.elasticsearch.password: "changeme"
EOF

# Logstash pipeline
cat > configs/logstash/pipeline/soc-pipeline.conf << 'EOF'
input {
  beats {
    port => 5044
  }
}

filter {
  # Add basic log source identification
  if [log][file][path] =~ "auth.log" {
    mutate { add_field => { "log_source" => "linux_auth" } }
  }
  if [log][file][path] =~ "apache" {
    mutate { add_field => { "log_source" => "apache" } }
  }
  if [log][file][path] =~ "windows-sim" {
    mutate { add_field => { "log_source" => "windows_sim" } }
  }
}

output {
  elasticsearch {
    hosts => ["http://172.20.0.10:9200"]
    user => "elastic"
    password => "changeme"
    index => "soc-logs-%{+YYYY.MM.dd}"
  }
}
EOF

# Kibana config
cat > configs/kibana/kibana.yml << 'EOF'
server.name: soc-kibana
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://172.20.0.10:9200"]
elasticsearch.username: "elastic"
elasticsearch.password: "changeme"
EOF

# Filebeat config
cat > configs/filebeat/filebeat.yml << 'EOF'
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/ubuntu-web/auth.log
    - /var/log/ubuntu-web/apache2/*.log
    - /var/log/windows-sim/*.json
    - /var/log/suricata/eve.json
  json.keys_under_root: true
  json.add_error_key: true

output.logstash:
  hosts: ["172.20.0.11:5044"]

setup.kibana:
  host: "172.20.0.12:5601"
EOF

echo -e "${GREEN}✓${NC} Configuration files created"
echo ""

# Start the lab
echo -e "${YELLOW}Starting SOC Detection Lab...${NC}"
echo "This will take 2-5 minutes depending on your internet speed"
echo ""

# Pull images first to show progress
echo -e "${BLUE}Pulling Docker images...${NC}"
docker compose pull

echo ""
echo -e "${BLUE}Starting containers...${NC}"
docker compose up -d

echo ""
echo -e "${YELLOW}Waiting for services to initialize...${NC}"
echo "This may take 2-3 minutes..."

# Wait for Elasticsearch
echo -n "Waiting for Elasticsearch"
for i in {1..60}; do
    if curl -s -u elastic:changeme http://localhost:9200 > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for Kibana
echo -n "Waiting for Kibana"
for i in {1..60}; do
    if curl -s http://localhost:5601/api/status > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ SOC Detection Lab is ready!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Access Points:${NC}"
echo -e "  Kibana (SOC Dashboard): ${YELLOW}http://localhost:5601${NC}"
echo -e "    Username: ${YELLOW}elastic${NC}"
echo -e "    Password: ${YELLOW}changeme${NC}"
echo ""
echo -e "  Elasticsearch API: ${YELLOW}http://localhost:9200${NC}"
echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo -e "  View logs:        ${YELLOW}docker compose logs -f${NC}"
echo -e "  Check status:     ${YELLOW}docker compose ps${NC}"
echo -e "  Stop lab:         ${YELLOW}docker compose stop${NC}"
echo -e "  Destroy lab:      ${YELLOW}docker compose down -v${NC}"
echo ""
echo -e "  Access Kali:      ${YELLOW}docker compose exec kali-attacker bash${NC}"
echo -e "  Access Web Server: ${YELLOW}docker compose exec ubuntu-web bash${NC}"
echo ""
echo -e "${BLUE}Generate test traffic:${NC}"
echo -e "  ${YELLOW}docker compose exec kali-attacker nmap -sV 172.20.0.50${NC}"
echo -e "  ${YELLOW}curl http://localhost:8080${NC}"
echo ""
echo -e "${GREEN}Happy hunting! 🔍${NC}"
