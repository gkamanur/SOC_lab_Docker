# Docker SOC Lab - 5-Minute Quick Start

## Why Docker? 🐳

**15 minutes** vs 4-6 hours (VMs)  
**8GB RAM** vs 16GB+ (VMs)  
**Portable** - Share your entire lab as a single `docker-compose.yml`  
**Interview-ready** - Spin up in minutes to demo live

---

## Prerequisites

✅ Docker installed (version 20.10+)  
✅ Docker Compose installed (version 2.0+)  
✅ 8GB RAM available  
✅ 20GB free disk space

**Check if you have Docker**:
```bash
docker --version
docker compose version
```

**Don't have Docker? Install in 2 minutes**:
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker run hello-world
```

---

## Deploy Entire Lab (ONE COMMAND)

```bash
cd /home/guruvenu/SOC-Detection-Lab/docker-deployment
./scripts/start-lab.sh
```

**That's it!** The script will:
1. Check Docker is installed
2. Create configuration files
3. Pull Docker images
4. Start all containers
5. Wait for services to be ready
6. Display access URLs

**Time: 15-20 minutes** (first run with downloads)  
**Subsequent starts: 2-3 minutes**

---

## Access Your Lab

**Kibana (SOC Dashboard)**:
- URL: http://localhost:5601
- Login: `elastic` / `changeme`

**Elasticsearch API**:
- URL: http://localhost:9200
- Login: `elastic` / `changeme`

**Wazuh Dashboard**:
- URL: https://localhost:443
- Login: `admin` / `admin`

---

## Generate Test Traffic

### From your host machine:

```bash
# Web request to Ubuntu server
curl http://localhost:8080

# Scan from Kali attacker
docker compose exec kali-attacker nmap -sV 172.20.0.50

# SSH brute force simulation
docker compose exec kali-attacker hydra -l webadmin -P /usr/share/wordlists/rockyou.txt ssh://172.20.0.50 -t 4
```

### Inside containers:

```bash
# Access Kali attacker
docker compose exec kali-attacker bash

# Inside Kali, run attacks
nmap -sV 172.20.0.50
nikto -h http://172.20.0.50
```

```bash
# Access Ubuntu web server
docker compose exec ubuntu-web bash

# Generate auth events
for i in {1..10}; do su - baduser 2>/dev/null; done
```

---

## View Logs in Kibana

1. Open http://localhost:5601
2. Go to **Discover** (left menu)
3. Create index pattern: `soc-logs-*`
4. Select time field: `@timestamp`
5. **View logs** - You should see:
   - Apache access logs
   - Linux auth logs
   - Windows simulated events
   - Network traffic from Suricata

---

## Common Commands

```bash
# Check status of all containers
docker compose ps

# View live logs from all services
docker compose logs -f

# View logs from specific service
docker compose logs -f elasticsearch

# Stop lab (keeps data)
docker compose stop

# Start lab again
docker compose start

# Destroy lab (removes all data)
docker compose down -v

# Restart single service
docker compose restart kibana

# Check resource usage
docker stats
```

---

## What's Running?

```bash
docker compose ps
```

You'll see:
- **soc-elasticsearch** - SIEM core (9200, 9300)
- **soc-logstash** - Log pipeline (5044, 9600)
- **soc-kibana** - Web dashboard (5601)
- **soc-wazuh-manager** - HIDS (1514, 1515, 55000)
- **soc-wazuh-dashboard** - Wazuh UI (443)
- **soc-suricata** - Network IDS
- **soc-ubuntu-web** - Target server (8080, 2222)
- **soc-windows-sim** - Windows log generator
- **soc-kali-attacker** - Attack tools
- **soc-filebeat** - Log shipper

---

## Troubleshooting

### Services won't start

```bash
# Check Docker memory allocation
docker info | grep Memory

# Increase in Docker Desktop:
# Settings → Resources → Memory: 10GB

# On Linux, check available memory
free -h
```

### Can't access Kibana

```bash
# Wait for Kibana to fully start (can take 2 minutes)
docker compose logs -f kibana

# Check if Elasticsearch is healthy
curl -u elastic:changeme http://localhost:9200
```

### Elasticsearch fails to start

```bash
# Increase vm.max_map_count on Linux
sudo sysctl -w vm.max_map_count=262144

# Make permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Port already in use

```bash
# Check what's using port 5601
sudo lsof -i :5601

# Change port in docker-compose.yml
# Change: "5601:5601" to "5602:5601"
```

### Clean slate (nuclear option)

```bash
docker compose down -v
docker system prune -a -f
docker volume prune -f
./scripts/start-lab.sh
```

---

## Comparison: Docker vs VMs

| Aspect | Docker (This) | VMs (Original) |
|--------|---------------|----------------|
| **Deployment** | 15-20 min | 4-6 hours |
| **RAM** | 8-12GB | 16GB+ |
| **Disk** | 10-15GB | 100GB+ |
| **Start time** | 2-3 min | 10-15 min |
| **Portability** | Excellent | Poor |
| **Sharing** | git clone + docker compose up | Multi-GB files |
| **Interview demo** | ✅ Fast | ⚠️ Requires pre-start |
| **Windows support** | Simulated | Full OS |
| **Realism** | 85% | 95% |

**Recommendation**: 
- **Docker for**: Learning, interviews, portfolios, quick demos
- **VMs for**: Deep Windows forensics, production-level realism

---

## Interview Demo Workflow

**Before interview (10 minutes before)**:
```bash
cd /home/guruvenu/SOC-Detection-Lab/docker-deployment
./scripts/start-lab.sh

# Wait 3 minutes, then verify
open http://localhost:5601
```

**During interview**:
```bash
# Show architecture
cat docker-compose.yml

# Generate attack
docker compose exec kali-attacker nmap -sV 172.20.0.50

# Show logs in Kibana
# Navigate to Discover → filter logs

# Explain detection logic
```

**After interview**:
```bash
docker compose stop
```

**Result**: Interviewers see working SOC lab in action, not theory.

---

## Extending the Lab

### Add custom detection rules

1. Create rule file: `detection-rules/my-rule.yml`
2. Add to Logstash pipeline: `configs/logstash/pipeline/soc-pipeline.conf`
3. Restart Logstash: `docker compose restart logstash`

### Add more attack scenarios

1. Create script: `attack-scenarios/my-attack.sh`
2. Mount in Kali: Already configured
3. Run: `docker compose exec kali-attacker bash /opt/attack-scenarios/my-attack.sh`

### Persist data across restarts

Data is automatically persisted in Docker volumes:
```bash
docker volume ls | grep soc
```

To backup:
```bash
docker run --rm -v soc-es-data:/data -v $(pwd):/backup ubuntu tar czf /backup/es-data-backup.tar.gz /data
```

---

## Resource Optimization

**If running on laptop with limited resources**:

Edit `docker-compose.yml`:
```yaml
elasticsearch:
  environment:
    - "ES_JAVA_OPTS=-Xms2g -Xmx2g"  # Reduced from 4g

logstash:
  environment:
    - "LS_JAVA_OPTS=-Xms512m -Xmx512m"  # Reduced from 1g
```

**Minimal mode** (just SIEM core):
```bash
docker compose up -d elasticsearch logstash kibana filebeat ubuntu-web
```

---

## Exporting Your Lab

**Share with others** (or between machines):

```bash
# Save images
docker save soc-elasticsearch soc-kibana soc-logstash | gzip > soc-lab-images.tar.gz

# Share entire config
tar czf soc-lab-config.tar.gz docker-compose.yml configs/ dockerfiles/

# On new machine
gunzip -c soc-lab-images.tar.gz | docker load
tar xzf soc-lab-config.tar.gz
docker compose up -d
```

**Or just share Git repo** (recommended):
```bash
git clone <your-soc-lab-repo>
cd docker-deployment
./scripts/start-lab.sh
```

---

## Next Steps

1. ✅ **Lab is running** - You're here
2. 📊 **Import dashboards** - `detection-rules/` directory
3. 🔍 **Run detections** - Create alerts
4. 🎯 **Simulate attacks** - Validate detections
5. 📝 **Practice triage** - docs/ALERT-TRIAGE.md
6. 🎤 **Prepare demo** - docs/INTERVIEW-GUIDE.md

---

## Full Documentation

- [Complete Docker Setup](./README.md)
- [Detection Engineering](../docs/DETECTION-ENGINEERING.md)
- [Alert Triage](../docs/ALERT-TRIAGE.md)
- [Interview Guide](../docs/INTERVIEW-GUIDE.md)
- [VM Deployment](../docs/SETUP.md) (alternative)

---

## Success Metrics

After running `./scripts/start-lab.sh`:

✅ All containers running: `docker compose ps`  
✅ Elasticsearch healthy: `curl localhost:9200`  
✅ Kibana accessible: `http://localhost:5601`  
✅ Logs flowing: Check Kibana Discover  
✅ Attacks work: `nmap` from Kali generates alerts

---

## Common Questions

**Q: Do I need Windows for this?**  
A: No! Runs on Linux, macOS, or Windows with WSL2.

**Q: Can I use this in interviews?**  
A: Absolutely! That's what it's designed for.

**Q: How do I update?**  
A: `docker compose pull && docker compose up -d`

**Q: Where is data stored?**  
A: Docker volumes (persists across restarts)

**Q: Can I run this on cloud (AWS/Azure)?**  
A: Yes! Launch Ubuntu instance, install Docker, run script.

**Q: Does this require internet after setup?**  
A: No, runs completely offline once images are downloaded.

---

**You now have a production-grade SOC lab running in Docker. Deploy anywhere, demo anytime, share easily.** 🚀

