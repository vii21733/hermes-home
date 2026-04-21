---
name: network-connectivity-testing
title: Network Connectivity Testing in Restricted Environments
description: Test internet speed and connectivity when traditional tools (ping, speedtest-cli) are unavailable due to container restrictions. Uses cascading fallback methods.
tags: [network, connectivity, speed-test, troubleshooting, restricted-environment, container]
---

# Network Connectivity Testing in Restricted Environments

## Problem

Standard network testing tools often fail in containerized/restricted environments:
- `ping` fails: "socktype: SOCK_RAW" (raw sockets blocked)
- `speedtest-cli` fails: Can't install (externally-managed-environment)
- Speed test servers fail: Connection timeouts or blocked

## Solution: Cascading Fallback Method

Try methods in order until one works:

### Method 1: Direct Speed Test (Usually Fails)
```bash
# Try downloading from speed test servers
curl -o /dev/null -w "Speed: %{speed_download} bytes/sec\n" \
  https://speed.hetzner.de/100MB.bin -s --max-time 30
```
**Likely result:** Exit code 60 (SSL error) or connection failed

### Method 2: Install speedtest-cli (Usually Fails)
```bash
pip install speedtest-cli
```
**Result:** "externally-managed-environment" error

### Method 3: Alternative Speed Test Server (May Fail)
```bash
curl -o /dev/null -w "Speed: %{speed_download}\n" \
  https://speedtest.tele2.net/10MB.zip -s --max-time 30
```
**Likely result:** Exit code 7 (connection failed)

### Method 4: Basic HTTP Connectivity Test (✅ Works)
```bash
curl -s -w "HTTP: %{http_code}\nTime: %{time_total}s\n" \
  https://httpbin.org/get -o /dev/null
```
**Expected result:** HTTP 200, response time ~0.5-2s

### Method 5: DNS Resolution Test (✅ Works)
```bash
# If dig is available
dig +short google.com

# Or use nslookup
nslookup google.com
```

## Working Commands Summary

| Test | Command | Expected |
|------|---------|----------|
| **HTTP Connectivity** | `curl -s -w "%{http_code}" https://httpbin.org/get -o /dev/null` | `200` |
| **Response Time** | `curl -s -w "%{time_total}s" https://httpbin.org/get -o /dev/null` | `0.5-3s` |
| **DNS Resolution** | `dig +short google.com` | IP addresses |
| **Download Speed** | `curl -o /dev/null -w "%{speed_download}" [URL]` | bytes/sec |

## Interpreting Results

| Result | Meaning |
|--------|---------|
| HTTP 200, <1s | ✅ Fast connection |
| HTTP 200, 1-3s | ⚠️ Moderate latency |
| HTTP 200, >3s | ⚠️ Slow/loaded connection |
| HTTP non-200 | 🔍 Check specific error |
| Connection timeout | ❌ No internet or blocked |

## Environment Restrictions Reference

| Error | Cause | Workaround |
|-------|-------|------------|
| "socktype: SOCK_RAW" | Container lacks CAP_NET_RAW | Use HTTP-based tests |
| "externally-managed-environment" | PEP 668, system Python | Use system packages or HTTP tests |
| Exit code 60 | SSL/TLS error | Try different server |
| Exit code 7 | Connection failed | Try different protocol/server |

## Method 6: Parallel Downloads for Bandwidth Testing (✅ Advanced)

When single large file downloads fail (403, connection errors), use **parallel downloads** to saturate the connection:

```python
import requests
import concurrent.futures
import time

# Download multiple smaller files in parallel
test_urls = [
 "https://speed.cloudflare.com/__down?bytes=10000000",  # 10MB
 "https://speed.cloudflare.com/__down?bytes=10000000",
 "https://speed.cloudflare.com/__down?bytes=10000000",
 "https://speed.cloudflare.com/__down?bytes=10000000",
 "https://speed.cloudflare.com/__down?bytes=10000000",
]

def download_test(url):
 start = time.time()
 r = requests.get(url, stream=True, timeout=20)
 if r.status_code == 200:
 size = sum(len(chunk) for chunk in r.iter_content(8192))
 elapsed = time.time() - start
 speed = (size * 8) / (elapsed * 1000000)  # Mbps
 return {'success': True, 'bytes': size, 'speed': speed}
 return {'success': False}

# Run in parallel
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
 results = list(executor.map(download_test, test_urls))

# Calculate effective throughput
successful = [r for r in results if r['success']]
total_bytes = sum(r['bytes'] for r in successful)
total_time = max(r['time'] for r in successful)  # Use max time (parallel)
effective_speed = (total_bytes * 8) / (total_time * 1000000)

print(f"Effective Speed: {effective_speed:.2f} Mbps")
```

**Why this works:**
- Individual large file downloads may be rate-limited or blocked
- Multiple parallel connections bypass per-connection limits
- Total throughput = sum of all parallel streams
- Simulates real-world usage (browsers use 6+ parallel connections)

**When to use:**
- Single 100MB+ downloads fail with 403/connection errors
- Need to test actual bandwidth capacity
- Environment has per-connection rate limits

## Full Working Script

```bash
#!/bin/bash
echo "=== Network Connectivity Test ==="

# Test 1: Basic HTTP connectivity
echo -n "HTTP connectivity: "
HTTP_CODE=$(curl -s -w "%{http_code}" https://httpbin.org/get -o /dev/null --max-time 10)
if [ "$HTTP_CODE" = "200" ]; then
 echo "✅ OK (HTTP $HTTP_CODE)"
else
 echo "❌ Failed (HTTP $HTTP_CODE)"
fi

# Test 2: Response time
echo -n "Response time: "
TIME=$(curl -s -w "%{time_total}" https://httpbin.org/get -o /dev/null --max-time 10)
echo "${TIME}s"

# Test 3: DNS (if dig available)
if command -v dig &> /dev/null; then
 echo -n "DNS resolution: "
 if dig +short google.com &> /dev/null; then
 echo "✅ Working"
 else
 echo "❌ Failed"
 fi
else
 echo "DNS resolution: ⏭️ Skipped (dig not available)"
fi

echo "=== Test Complete ==="
```

## Key Insight

In restricted containers, **HTTP-based tests are the only reliable method**. Traditional networking tools require capabilities that containers often lack. Always have HTTP fallbacks ready.

## References
- PEP 668: Externally Managed Python Environments
- Linux capabilities: CAP_NET_RAW
- curl write-out variables: https://everything.curl.dev.dev/cmdline/write-out.html