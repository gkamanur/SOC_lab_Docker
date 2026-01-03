# Suricata IDS Guide - SOC Detection Lab

## Overview

Suricata is a high-performance Network IDS (Intrusion Detection System), IPS (Intrusion Prevention System), and Network Security Monitoring (NSM) engine. In this lab, it acts as the primary network-based detection mechanism, capturing and analyzing traffic to and from the `ubuntu-web` server.

## Architecture

```
[ Kali Attacker ] -> [ Network Traffic ] -> [ Suricata (monitoring eth0 of ubuntu-web) ]
                                                        |
                                                        v
                                             [ EVE JSON Logs ]
                                                        |
                                                        v
                                               [ Filebeat ] -> [ Logstash ] -> [ Elasticsearch ] -> [ Kibana ]
```

## Configuration Files

- Full Config: `configs/suricata/suricata.yaml`
- Minimal Config: `configs/suricata/suricata-minimal.yaml`
- Custom Rules: `configs/suricata/rules/custom.rules`
- Update Script: `configs/suricata/update-rules.sh`

## Minimal Mode Optimizations

To run on systems with limited RAM (like your 1.57GB environment), Suricata is optimized with:
- **Memory Limit**: 150MB
- **Threads**: Single detection thread (CPU saver)
- **Rules**: Uses only `custom.rules` by default to reduce memory usage from the ~30k ET rules.
- **Buffers**: Reduced flow and stream memory caps.

## Rule Management

### Custom Rules
You can add your own rules to `configs/suricata/rules/custom.rules`. For example:
```suricata
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Detected"; itype:8; sid:1000001; rev:1;)
```

### Emerging Threats (ET) Rules
To download the full set of Emerging Threats Open rules (requires 8GB+ RAM recommended):
1. Shell into the container: `docker compose exec suricata bash`
2. Run update: `/usr/local/bin/update-rules.sh`

## Verification & Testing

### Running Tests
Use the provided test script to trigger various detections:
```bash
./scripts/test-suricata.sh [docker-compose-file.yml]
```

### Manual Inspection
View alerts in real-time:
```bash
docker compose exec filebeat tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'
```

## Troubleshooting

### Suricata not detecting traffic
Ensure Suricata is in the same network namespace as the target:
```yaml
network_mode: "service:ubuntu-web"
```

### Out of Memory (OOM) - Suricata
If Suricata crashes, check memory usage:
```bash
docker stats soc-suricata-mini
```
If it's hitting 100% of its 150MB limit, you may need to disable more rule categories or reduce the `stream.memcap` in `suricata-minimal.yaml`.

### Out of Memory (OOM) - Logstash
If alerts are generated but don't reach Kibana, check Logstash logs:
```bash
docker logs soc-logstash-mini
```
If you see `java.lang.OutOfMemoryError`, the GeoIP filter is likely the cause. In minimal mode, GeoIP is disabled to save RAM. Ensure `LS_JAVA_OPTS` is set to at least `-Xmx256m` and the container has a `mem_limit` of at least `512m`.

### Alerts not showing in Kibana (JSON Parsing)
If you see documents in Elasticsearch but no fields like `alert.signature`, the Logstash JSON filter may be failing to find the raw string. In newer Beats versions, the raw log is in `[event][original]`. Ensure your Logstash config handles both `message` and `event.original`.
