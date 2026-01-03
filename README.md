# Docker-Based SOC Detection Lab

## Overview

This is the **containerized version** of the SOC Detection Lab. Instead of VMs, we use Docker containers for faster deployment, lower resource usage, and better portability.

**Advantages over VM-based deployment:**
- ⚡ **Faster**: Deploy entire lab in 15-20 minutes (vs 4-6 hours)
- 💾 **Lighter**: Uses 8-12GB RAM (vs 16GB+ for VMs)
- 🚀 **Portable**: Share lab config via Docker Compose
- 🔄 **Reproducible**: Identical environment every time
- 🧹 **Clean**: Teardown and rebuild in minutes
- 🏗️ **Modern**: Reflects containerized SOC infrastructure

---

## Architecture

```
Docker Network: soc-network (172.20.0.0/16)

┌─────────────────────────────────────────────────────────────┐
│                      Host Machine                           │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Docker Network (soc-network)              │ │
│  │                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐   │ │
│  │  │ Elasticsearch│  │  Logstash    │  │   Kibana    │   │ │
│  │  │ :9200        │  │  :5044       │  │   :5601     │   │ │
│  │  │ 172.20.0.10  │  │  172.20.0.11 │  │ 172.20.0.12 │   │ │
│  │  └──────────────┘  └──────────────┘  └─────────────┘   │ │
│  │                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐   │ │
│  │  │   Wazuh      │  │  Suricata    │  │  Filebeat   │   │ │
│  │  │   Manager    │  │     IDS      │  │   Shipper   │   │ │
│  │  │ 172.20.0.20  │  │  172.20.0.30 │  │ 172.20.0.40 │   │ │
│  │  └──────────────┘  └──────────────┘  └─────────────┘   │ │
│  │                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐                    │ │
│  │  │  Windows     │  │   Ubuntu     │                    │ │
│  │  │  Victim      │  │  Web Server  │                    │ │
│  │  │ (simulated)  │  │  172.20.0.50 │                    │ │
│  │  │ 172.20.0.60  │  │  Apache      │                    │ │
│  │  └──────────────┘  └──────────────┘                    │ │
│  │                                                        │ │
│  │  ┌──────────────┐                                      │ │
│  │  │    Kali      │                                      │ │
│  │  │   Attacker   │                                      │ │
│  │  │ 172.20.0.70  │                                      │ │
│  │  └──────────────┘                                      │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

Exposed Ports:
- 5601 → Kibana (SOC Dashboard)
- 9200 → Elasticsearch (API)
- 5044 → Logstash (Beats input)
- 443  → Wazuh Dashboard
```

---

## Quick Start (TL;DR)

```bash
# Clone and navigate
cd /home/guruvenu/SOC-Detection-Lab/docker-deployment

# Start entire lab
docker-compose up -d

# Wait 2-3 minutes for services to initialize

# Access Kibana
open http://localhost:5601
# Login: elastic / changeme

# Check status
docker-compose ps

# View logs
docker-compose logs -f elasticsearch kibana

# Stop lab
docker-compose down

# Destroy everything (including data)
docker-compose down -v
```

**Deployment time**: 15-20 minutes (first run with image downloads)  
**Subsequent starts**: 2-3 minutes

---

## System Requirements

**Minimum**:
- Docker Engine 20.10+
- Docker Compose 2.0+
- 8GB RAM
- 20GB free disk space
- Linux, macOS, or Windows with WSL2

**Recommended**:
- 12GB RAM
- 40GB free disk space
- SSD for better Elasticsearch performance

---

## Installation

### 1. Install Docker (if not already installed)

**Ubuntu/Debian**:
```bash
# Remove old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install dependencies
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (no sudo needed)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

**macOS**:
```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Or via Homebrew:
brew install --cask docker
```

**Windows**:
- Install Docker Desktop from https://www.docker.com/products/docker-desktop
- Enable WSL2 integration

### 2. Configure Docker Resources

**Linux**: Edit `/etc/docker/daemon.json`:
```json
{
  "default-address-pools": [
    {
      "base": "172.20.0.0/16",
      "size": 24
    }
  ]
}
```

**Docker Desktop (Mac/Windows)**:
- Open Docker Desktop → Settings → Resources
- Set RAM: 10GB minimum
- Set CPUs: 4+ cores
- Set Disk: 40GB+

Restart Docker:
```bash
sudo systemctl restart docker  # Linux
# Or restart Docker Desktop
```

---

## Deployment Steps

### Step 1: Navigate to Docker Directory

```bash
cd /home/guruvenu/SOC-Detection-Lab/docker-deployment
```

### Step 2: Review Configuration

```bash
# View docker-compose.yml
cat docker-compose.yml

# View environment variables
cat .env
```

### Step 3: Start Services

```bash
# Start all containers
docker compose up -d

# Watch logs during startup
docker compose logs -f

# Ctrl+C to stop watching (containers keep running)
```

**Startup sequence**:
1. Elasticsearch (30-60 seconds)
2. Kibana (60-90 seconds)
3. Logstash (30 seconds)
4. Wazuh, Suricata, Web servers (20-30 seconds)

### Step 4: Verify Services

```bash
# Check running containers
docker compose ps

# Should show all services as "Up"

# Test Elasticsearch
curl -u elastic:changeme http://localhost:9200

# Test Kibana (should return HTML)
curl -I http://localhost:5601
```

### Step 5: Access Dashboards

**Kibana (SOC Dashboard)**:
- URL: http://localhost:5601
- Username: `elastic`
- Password: `changeme` (configurable in .env)

**Wazuh Dashboard**:
- URL: https://localhost:443
- Username: `admin`
- Password: `admin` (change after first login)

### Step 6: Generate Test Logs

```bash
# Execute command in Ubuntu web server
docker compose exec ubuntu-web bash

# Inside container, generate auth events
for i in {1..5}; do su - baduser 2>/dev/null; done

# Generate web requests
curl http://localhost
curl http://localhost/admin
curl http://localhost/test

# Exit container
exit

# Execute in Kali attacker
docker compose exec kali-attacker bash

# Scan web server
nmap -sV 172.20.0.50

# Exit
exit
```

### Step 7: View Logs in Kibana

1. Open http://localhost:5601
2. Go to **Discover**
3. Create index pattern: `filebeat-*`
4. Select time field: `@timestamp`
5. View incoming logs

---

## Project Structure

```
docker-deployment/
├── README.md (this file)
├── docker-compose.yml (main orchestration)
├── .env (environment variables)
├── .env.example (example configuration)
├── configs/
│   ├── elasticsearch/
│   │   └── elasticsearch.yml
│   ├── logstash/
│   │   ├── logstash.yml
│   │   └── pipeline/
│   │       └── soc-pipeline.conf
│   ├── kibana/
│   │   └── kibana.yml
│   ├── suricata/
│   │   └── suricata.yaml
│   ├── filebeat/
│   │   └── filebeat.yml
│   └── wazuh/
│       └── ossec.conf
├── dockerfiles/
│   ├── Dockerfile.ubuntu-web
│   ├── Dockerfile.kali-attacker
│   └── Dockerfile.windows-sim
├── scripts/
│   ├── setup.sh (automated setup)
│   ├── start-lab.sh (start services)
│   ├── stop-lab.sh (stop services)
│   ├── status.sh (check health)
│   ├── generate-events.sh (create test data)
│   └── cleanup.sh (remove all data)
├── detection-rules/
│   └── (KQL rules for Kibana)
├── attack-scenarios/
│   └── (attack simulation scripts)
└── docs/
    ├── DOCKER-SETUP.md
    ├── TROUBLESHOOTING.md
    └── COMPARISON.md (Docker vs VM)
```

---

## Container Details

### Elasticsearch (SIEM Core)
- **Image**: `docker.elastic.co/elasticsearch/elasticsearch:8.11.0`
- **Memory**: 4GB heap
- **Purpose**: Log storage and search
- **Port**: 9200

### Logstash (Log Pipeline)
- **Image**: `docker.elastic.co/logstash/logstash:8.11.0`
- **Memory**: 1GB heap
- **Purpose**: Log parsing and normalization
- **Port**: 5044 (Beats input)

### Kibana (Web UI)
- **Image**: `docker.elastic.co/kibana/kibana:8.11.0`
- **Memory**: 1GB
- **Purpose**: Visualization and analysis
- **Port**: 5601

### Wazuh Manager
- **Image**: `wazuh/wazuh:4.7.0`
- **Memory**: 2GB
- **Purpose**: HIDS, FIM, vulnerability detection
- **Port**: 1514, 1515, 443

### Suricata IDS
- **Image**: `jasonish/suricata:latest`
- **Memory**: 512MB
- **Purpose**: Network intrusion detection
- **Mode**: Bridge network monitoring

### Ubuntu Web Server
- **Image**: Custom (Ubuntu 22.04 + Apache)
- **Purpose**: Attack target, log generation
- **Services**: Apache, SSH, Filebeat

### Kali Attacker
- **Image**: `kalilinux/kali-rolling:latest`
- **Purpose**: Attack simulation
- **Tools**: nmap, hydra, metasploit

---

## Data Persistence

All data is stored in Docker volumes:

```bash
# List volumes
docker volume ls | grep soc

# Volumes created:
# - soc-es-data (Elasticsearch indices)
# - soc-kibana-data (Kibana dashboards)
# - soc-logstash-data (Pipeline state)
# - soc-wazuh-data (Wazuh alerts)
```

**To reset everything**:
```bash
docker compose down -v  # WARNING: Deletes all data
docker compose up -d    # Fresh start
```

---

## Common Commands

### Start/Stop

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d elasticsearch

# Stop all services
docker compose stop

# Stop and remove containers (keeps data)
docker compose down

# Stop and remove everything including data
docker compose down -v
```

### Monitoring

```bash
# View all container status
docker compose ps

# View logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f elasticsearch

# Check resource usage
docker stats

# View network
docker network inspect soc-network
```

### Access Containers

```bash
# Shell into Elasticsearch
docker compose exec elasticsearch bash

# Shell into Ubuntu web server
docker compose exec ubuntu-web bash

# Shell into Kali attacker
docker compose exec kali-attacker bash

# Run one-off command
docker compose exec ubuntu-web cat /var/log/auth.log
```

### Restart Services

```bash
# Restart single service
docker compose restart logstash

# Restart all services
docker compose restart

# Rebuild and restart (after config changes)
docker compose up -d --build
```

---

## Advantages vs VM Deployment

| Feature | Docker | VMs |
|---------|--------|-----|
| **Deployment Time** | 15-20 min | 4-6 hours |
| **RAM Usage** | 8-12GB | 16GB+ |
| **Disk Usage** | 10-15GB | 100GB+ |
| **Startup Time** | 2-3 min | 10-15 min |
| **Portability** | Excellent (docker-compose.yml) | Poor (large VM files) |
| **Snapshot/Restore** | Instant (docker-compose down/up) | Minutes |
| **Networking** | Simple (Docker networks) | Complex (NAT, bridges) |
| **Resource Sharing** | Dynamic | Static allocation |
| **Updates** | Pull new images | Manual OS updates |
| **Isolation** | Container-level | Full OS isolation |

**Trade-offs**:
- ❌ Windows containers require Linux host + Wine (or separate Windows Docker setup)
- ❌ Less realistic for Windows endpoint behavior
- ❌ Shared kernel (less isolation than VMs)
- ✅ But much faster, lighter, and easier to share

---

## Windows Simulation Strategy

Since running actual Windows containers on Linux is complex, we use two approaches:

### Approach 1: Log Simulation (Default)
- Generate Windows-like logs (Sysmon, Security events)
- Inject into Logstash for processing
- Sufficient for detection rule development

### Approach 2: Wine-based Container
- Ubuntu container with Wine
- Run Windows tools (PowerShell, Mimikatz)
- Generate real Windows-style artifacts
- Good enough for most scenarios

### Approach 3: Windows Docker Host (Advanced)
- Separate Windows machine with Docker
- Run actual Windows containers
- Connect to same Docker network
- Most realistic but requires Windows host

**We default to Approach 1** for simplicity and cross-platform compatibility.

---

## Next Steps

1. **Deploy the lab**: Follow Step 1-7 above
2. **Import detection rules**: `detection-rules/README.md`
3. **Run attack scenarios**: `attack-scenarios/README.md`
4. **Practice investigations**: Generate alerts and triage
5. **Share your lab**: Export `docker-compose.yml` and configs

---

## Troubleshooting

See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for common issues.

**Quick fixes**:

```bash
# Service won't start
docker compose logs <service-name>

# Out of memory
# Increase Docker memory in Docker Desktop settings

# Port already in use
# Change port in docker-compose.yml
# ports: "5602:5601" instead of "5601:5601"

# Clean slate
docker compose down -v
docker system prune -a
docker compose up -d
```

---

## Interview Demo Mode

**Quick demo script**:

```bash
# Start lab
./scripts/start-lab.sh

# Generate attack activity
./scripts/generate-events.sh --attack=credential-dump

# Open Kibana
open http://localhost:5601

# Show alert firing
# Walk through investigation
# Explain detection logic

# Stop lab
./scripts/stop-lab.sh
```

---

## Contributing

Want to improve this Docker deployment?

- Add more realistic Windows simulation
- Optimize resource usage
- Add more attack containers
- Improve monitoring dashboards

Pull requests welcome!

---

**This Docker deployment makes the SOC Detection Lab portable, fast, and interview-ready. Share your docker-compose.yml and anyone can spin up your exact lab in minutes.** 🐳

