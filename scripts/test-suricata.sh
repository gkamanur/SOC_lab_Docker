#!/bin/bash

# Suricata Detection Testing Script
# Tests various attack scenarios to verify Suricata is detecting threats

set -e

COMPOSE_FILE="${1:-docker-compose.yml}"
TARGET_IP="172.20.0.50"
WAIT_TIME=5

echo "============================================"
echo "Suricata Detection Testing Script"
echo "============================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if containers are running
echo "[*] Checking if lab is running..."
if ! docker compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    echo -e "${RED}[!] Lab is not running. Start it first with: docker compose up -d${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] Lab is running${NC}"
echo ""

# Function to wait and check for alerts
check_alerts() {
    local test_name="$1"
    echo "[*] Waiting ${WAIT_TIME}s for alerts to be logged..."
    sleep $WAIT_TIME
    
    # Check if alerts were generated
    local alert_count=$(docker compose -f "$COMPOSE_FILE" exec -T filebeat grep -c "event_type.*alert" /var/log/suricata/eve.json 2>/dev/null || echo "0")
    
    if [ "$alert_count" -gt 0 ]; then
        echo -e "${GREEN}[✓] $test_name: $alert_count alerts detected${NC}"
    else
        echo -e "${YELLOW}[!] $test_name: No alerts detected (may be expected)${NC}"
    fi
    echo ""
}

# Test 1: Nmap SYN Scan
echo "============================================"
echo "Test 1: Nmap SYN Scan Detection"
echo "============================================"
echo "[*] Running nmap SYN scan from Kali container..."
docker compose -f "$COMPOSE_FILE" exec -T kali-attacker nmap -sS -p 80,22,443 $TARGET_IP >/dev/null 2>&1 || true
check_alerts "Nmap SYN Scan"

# Test 2: Nmap Service Version Detection
echo "============================================"
echo "Test 2: Nmap Version Detection"
echo "============================================"
echo "[*] Running nmap version detection..."
docker compose -f "$COMPOSE_FILE" exec -T kali-attacker nmap -sV -p 80 $TARGET_IP >/dev/null 2>&1 || true
check_alerts "Nmap Version Detection"

# Test 3: HTTP Directory Traversal
echo "============================================"
echo "Test 3: Directory Traversal Attack"
echo "============================================"
echo "[*] Attempting directory traversal..."
docker compose -f "$COMPOSE_FILE" exec -T kali-attacker curl -s "http://$TARGET_IP/../../../../etc/passwd" >/dev/null 2>&1 || true
check_alerts "Directory Traversal"

# Test 4: SQL Injection Attempt
echo "============================================"
echo "Test 4: SQL Injection Attack"
echo "============================================"
echo "[*] Attempting SQL injection..."
docker compose -f "$COMPOSE_FILE" exec -T kali-attacker curl -s "http://$TARGET_IP/login?user=admin&pass=' OR '1'='1" >/dev/null 2>&1 || true
check_alerts "SQL Injection"

# Test 5: XSS Attempt
echo "============================================"
echo "Test 5: Cross-Site Scripting (XSS)"
echo "============================================"
echo "[*] Attempting XSS attack..."
docker compose -f "$COMPOSE_FILE" exec -T kali-attacker curl -s "http://$TARGET_IP/search?q=<script>alert('xss')</script>" >/dev/null 2>&1 || true
check_alerts "XSS Attack"

# Test 6: Port Sweep
echo "============================================"
echo "Test 6: Port Sweep Detection"
echo "============================================"
echo "[*] Running port sweep..."
docker compose -f "$COMPOSE_FILE" exec -T kali-attacker nmap -p 1-100 $TARGET_IP >/dev/null 2>&1 || true
check_alerts "Port Sweep"

# Test 7: Suspicious User Agent
echo "============================================"
echo "Test 7: Suspicious User Agent Detection"
echo "============================================"
echo "[*] Sending request with scanner user agent..."
docker compose -f "$COMPOSE_FILE" exec -T kali-attacker curl -s -A "sqlmap/1.0" "http://$TARGET_IP/" >/dev/null 2>&1 || true
check_alerts "Suspicious User Agent"

# Summary
echo "============================================"
echo "Test Summary"
echo "============================================"
echo "[*] Checking total alerts generated..."

# Get total alert count
TOTAL_ALERTS=$(docker compose -f "$COMPOSE_FILE" exec -T filebeat grep -c "event_type.*alert" /var/log/suricata/eve.json 2>/dev/null || echo "0")

echo -e "${GREEN}Total alerts detected: $TOTAL_ALERTS${NC}"
echo ""

# Show recent alerts
echo "[*] Recent alerts (last 5):"
docker compose -f "$COMPOSE_FILE" exec -T filebeat tail -n 5 /var/log/suricata/eve.json | grep "alert" | jq -r '.alert.signature' 2>/dev/null || echo "No alerts found or jq not available"

echo ""
echo "============================================"
echo "Verification Steps"
echo "============================================"
echo "1. View all Suricata logs:"
echo "   docker compose -f $COMPOSE_FILE exec filebeat cat /var/log/suricata/eve.json"
echo ""
echo "2. View only alerts:"
echo "   docker compose -f $COMPOSE_FILE exec filebeat grep 'event_type.*alert' /var/log/suricata/eve.json"
echo ""
echo "3. Check alerts in Kibana:"
echo "   Open http://localhost:5601"
echo "   Go to Discover"
echo "   Filter: log_source: suricata_ids AND event_type: alert"
echo ""
echo "4. Check Suricata stats:"
echo "   docker compose -f $COMPOSE_FILE logs suricata | grep -i 'rule'"
echo ""
echo "============================================"
echo "Testing Complete!"
echo "============================================"
