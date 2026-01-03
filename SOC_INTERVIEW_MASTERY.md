# SOC Detection Lab: Mastery Guide for Senior Roles

This guide is designed to help you articulate the value, architecture, and technical challenges of this project in a **Senior SOC / Security Engineering interview**.

---

## 1. The "Elevator Pitch" (What is this?)

**"I built a containerized SOC Detection Lab using the ELK Stack (Elasticsearch, Logstash, Kibana) to simulate attacks and develop detection logic."**

### Key Wins to Highlight:
- **Infrastructure-as-Code**: Entire lab is defined in Docker Compose, making it portable and reproducible.
- **Resource Optimization**: Successfully deployed a JVM-heavy stack on a highly constrained environment (1.5GB RAM) by tuning heap sizes and container limits ("Micro Mode").
- **End-to-End Pipeline**: Configured the full log lifecycle: Generation (Attacks) → Collection (Filebeat) → Processing (Logstash) → Storage (Elasticsearch) → Analysis (Kibana).

---

## 2. Architecture Deep Dive

Understanding **Data Flow** is critical for senior roles. You must be able to trace a log from start to finish.

### The Pipeline (Micro Mode)

```mermaid
graph LR
    A[Attacker] -->|curl/nmap| B[Ubuntu Web Server]
    B -->|Generates| C[access.log]
    D[Filebeat] -->|Reads| C
    D -->|Ships (TCP 5044)| E[Logstash]
    E -->|Parses & Enriches| F[Elasticsearch]
    F -->|Indexes| G[Index: soc-logs-*]
    H[Kibana] -->|Queries (HTTP 9200)| F
```

### Component Roles
1. **Ubuntu Web Server (The Victim)**:
   - Runs Apache.
   - Generates `access.log` and `error.log`.
2. **Filebeat (The Shipper)**:
   - Lightweight agent.
   - **Why Filebeat?** It's lighter than Logstash. We use it to tail files and send them to the Logstash aggregator.
3. **Logstash (The Processor)**:
   - Receives logs from Filebeat.
   - **Senior Detail**: In a production setup, this is where we would do **GeoIP enrichment**, **DNS lookups**, and **grok parsing** to structure the data.
4. **Elasticsearch (The Database)**:
   - Search engine & NoSQL storage.
   - Stores logs as JSON documents.
5. **Kibana (The 'Single Pane of Glass')**:
   - Visualization UI. Use "Discover" for hunting and "Dashboards" for reporting.

---

## 3. Technical Challenges & Solutions (Interview Gold)

Senior interviewers ask about "a time you faced a technical challenge." Use this project!

### Challenge: Resource Constraints (The "Micro Mode" Story)
- **Problem**: The ELK stack typically requires 8GB+ RAM. Our environment had 1.5GB.
- **Impact**: Services crashed with OOM (Out Of Memory) errors; Kibana failed to connect.
- **Solution**:
  1. **Heap Tuning**: Reduced ES_JAVA_OPTS from 1GB → 256MB.
  2. **Container Limits**: Added `mem_limit` to prevent one service from starving the OS.
  3. **Architecture pivot**: Disabled heavy services (Wazuh, Suricata) to focus on core log analysis.
  4. **Troubleshooting**: Diagnosed a "Connection Reset" error in Kibana caused by a configuration mismatch (Kibana expecting Security, ES having it disabled).

---

## 4. Threat Hunting Walkthrough

"How do you detect a web scan?"

**Scenario**: An attacker scans the web server for vulnerabilities.

1. **Evidence**: `curl -I http://localhost:8080/admin`
2. **Log Artifact**: Apache `access.log` records a `404` status code.
3. **Detection Query (KQL)**:
   - `http.response.status_code : 404` (Broad)
   - `url.original : *admin* OR *passwd*` (Specific)
4. **Investigation Steps**:
   - Filter by `source.ip` (Who is attacking?)
   - Look for high volume of 404s in short time (Directory Brute Force).
   - Check if any 200 OK responses followed the 404s (Successful breach).

---

## 5. Senior-Level Concepts to Mention

When discussing this project, drop these concepts to sound like a senior engineer:

- **Observability vs. Logging**: "This lab provides observability into the web server's state via logs."
- **Normalization**: "If I had more resources, I would use the **Elastic Common Schema (ECS)** to normalize these logs, so Apache and Nginx logs look the same."
- **Detection Engineering**: "I treat detection rules as code—version controlled and tested against this lab."
- **Immutable Infrastructure**: "Because this is Dockerized, if a container is compromised, I can blow it away and redeploy in seconds."

---

## 6. Common Interview Questions Prepared

**Q: Why ELK instead of Splunk?**
A: "ELK is open-source/free for this lab context. Splunk is great but expensive. The fundamental skills (query logic, pipelining) transfer between both."

**Q: How would you scale this for a real enterprise?**
A: "Micro Mode is for a laptop. For enterprise, I'd move to a **Clustered Elasticsearch** (3+ nodes) for HA, put a **Queue (Kafka/Redis)** before Logstash to handle burst traffic, and use dedicated hardware."

**Q: How do you secure this stack?**
A: "Currently, security is disabled for resource reasons. In production, I would enable **X-Pack Security** (TLS for inter-node transport, RBAC for user access) and put Kibana behind a VPN or SSO."
