# HemoStat Quick Start Guide

## 5-Minute Setup

### Step 1: Copy .env file
```bash
cp .env.example .env
# Edit .env and add your OpenAI API key and Slack webhook
nano .env
```

### Step 2: Build Docker images
```bash
docker-compose build
```

### Step 3: Start services
```bash
docker-compose up -d
```

### Step 4: Verify services
```bash
docker-compose ps

# All 7 services should show "Up"
# - hemostat-redis
# - hemostat-monitor
# - hemostat-analyzer
# - hemostat-responder
# - hemostat-alert
# - hemostat-dashboard
# - hemostat-arcane
```

### Step 5: Access dashboards
- Streamlit: http://localhost:8501
- Arcane: http://localhost:3000

## Running Demo

### Terminal 1: Watch logs
```bash
docker-compose logs -f hemostat-monitor
```

### Terminal 2: Trigger CPU spike
```bash
docker exec hemostat-test-api apk add stress
docker exec hemostat-test-api stress --cpu 4 --timeout 30
```

### Watch the magic happen
1. **Seconds 0-30:** Monitor detects high CPU
2. **Seconds 30-33:** Analyzer determines it's real
3. **Seconds 33-38:** Responder restarts container
4. **Seconds 38+:** Alert sends Slack notification, Dashboard updates

**Total: ~13 seconds from detection to fix**

## What You're Looking At

### Monitor Logs
```
INFO:HemoStat-Monitor:Container: hemostat-test-api
INFO:HemoStat-Monitor:Anomalies: ['High CPU: 92.5%']
INFO:HemoStat-Monitor:Published health_alert
```

### Analyzer Logs
```
INFO:HemoStat-Analyzer:Real issue: CPU contention
INFO:HemoStat-Analyzer:Claude analysis: restart
INFO:HemoStat-Analyzer:Published remediation_needed
```

### Responder Logs
```
INFO:HemoStat-Responder:Executing restart for hemostat-test-api
INFO:HemoStat-Responder:Restarted container hemostat-test-api
INFO:HemoStat-Responder:Published remediation_complete
```

### Streamlit Dashboard
- Container grid shows red alert → turns green after fix
- Active Issues section shows detected problem
- Recent Actions section shows "RESTART: hemostat-test-api"

## Stop System

```bash
docker-compose down -v
```

This removes all containers, volumes, and networks. Restart with `docker-compose up -d`.

## Common Commands

```bash
# View logs for specific service
docker-compose logs hemostat-analyzer

# Follow logs in real-time
docker-compose logs -f hemostat-responder

# Restart specific service
docker-compose restart hemostat-monitor

# Execute command in container
docker exec hemostat-test-api apk add stress

# Access container shell
docker exec -it hemostat-monitor bash

# Check container health
docker-compose ps

# View Redis data
docker exec hemostat-redis redis-cli keys "*"

# Clear all data
docker-compose down -v
```

## Next Steps

1. **Modify Monitor thresholds** - Edit `agents/hemostat_monitor/hemostat_monitor.py` line ~24
2. **Add more remediation actions** - Edit `agents/hemostat_responder/hemostat_responder.py`
3. **Customize dashboard** - Edit `dashboard/app.py`
4. **Deploy to production** - See docs/DEPLOYMENT.md

## Troubleshooting

**Q: Services won't start**
A: Check Docker is running, rebuild: `docker-compose build && docker-compose up -d`

**Q: Analyzer throwing errors**
A: Check OPENAI_API_KEY is set, or system falls back to rule-based (still works!)

**Q: Dashboard not updating**
A: Refresh browser, wait 5 seconds for auto-refresh

**Q: Demo issue not detected**
A: Check Monitor logs: `docker-compose logs hemostat-monitor`

See TROUBLESHOOTING.md for more help.
