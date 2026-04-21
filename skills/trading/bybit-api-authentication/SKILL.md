---
name: bybit-api-authentication
title: Bybit API Authentication
description: HMAC SHA256 signature generation for Bybit API (GET and POST requests)
tags: [bybit, trading, api, authentication, hmac, crypto]
---

# Bybit API Authentication

Authentication guide for Bybit API (Demo and Mainnet) using HMAC SHA256 signatures.

## API Endpoints

- **Demo:** `https://api-demo.bybit.com`
- **Mainnet:** `https://api.bybit.com`

## Signature Algorithm

### For GET Requests

**Critical:** Do NOT include `sign` in the URL query string. Only send it in the `X-BAPI-SIGN` header.

```python
import time
import hmac
import hashlib
from urllib.parse import urlencode

# Generate timestamp in milliseconds
timestamp = str(int(time.time() * 1000))
recv_window = "5000"

# All params EXCEPT sign
params = {
    "accountType": "UNIFIED",  # or other endpoint-specific params
    "api_key": api_key,
    "recv_window": recv_window,
    "timestamp": timestamp
}

# Sort alphabetically by key
sorted_params = sorted(params.items(), key=lambda x: x[0])
query_string = "&".join([f"{k}={v}" for k, v in sorted_params])

# Build signature payload: timestamp + api_key + recv_window + queryString
sign_payload = timestamp + api_key + recv_window + query_string

# Generate signature
signature = hmac.new(
    api_secret.encode('utf-8'),
    sign_payload.encode('utf-8'),
    hashlib.sha256
).hexdigest()

# Build URL WITHOUT sign parameter
url = f"{base_url}/v5/account/wallet-balance?{query_string}"

headers = {
    "X-BAPI-API-KEY": api_key,
    "X-BAPI-TIMESTAMP": timestamp,
    "X-BAPI-RECV-WINDOW": recv_window,
    "X-BAPI-SIGN": signature
}

response = requests.get(url, headers=headers)
```

### For POST Requests

For POST requests, sign the JSON body string:

```python
import json

timestamp = str(int(time.time() * 1000))
recv_window = "5000"

# Request body - include endpoint-specific params only
body = {
 "category": "spot",
 "symbol": "BTCUSDT",
 "side": "Buy",
 "orderType": "Limit",
 "qty": "0.001",
 "price": "50000"
}

# IMPORTANT: JSON must use separators=(',', ':') for compact format
body_json = json.dumps(body, separators=(',', ':'))

# Build signature payload: timestamp + api_key + recv_window + body
sign_payload = timestamp + api_key + recv_window + body_json

signature = hmac.new(
 api_secret.encode('utf-8'),
 sign_payload.encode('utf-8'),
 hashlib.sha256
).hexdigest()

headers = {
 "X-BAPI-API-KEY": api_key,
 "X-BAPI-TIMESTAMP": timestamp,
 "X-BAPI-RECV-WINDOW": recv_window,
 "X-BAPI-SIGN": signature,
 "Content-Type": "application/json"
}

# CRITICAL: Use data=body_json, NOT json=body
response = requests.post(url, headers=headers, data=body_json)
```

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `10004 - Error sign` | Signature mismatch | For POST, use `data=body_json` not `json=body`. Ensure body JSON uses compact format `separators=(',', ':')` |
| `10002 - invalid request, please check your server timestamp` | Clock drift | Ensure system time is synced; increase recv_window if needed |
| `170140 - Order value exceeded lower limit` | Order too small | Minimum order value varies; try 0.001 BTC @ 50000 USDT (~5 USDT) |
| `170131 - Insufficient balance` | Not enough funds | Check wallet balance first |

## Important Notes

### POST Request Critical Details
1. **Body JSON format matters**: Use `json.dumps(body, separators=(',', ':'))` for compact JSON
2. **Use `data=` not `json=`**: `requests.post(url, headers=headers, data=body_json)` - the `json=` parameter adds Content-Type header but may modify the body
3. **Do NOT include api_key/timestamp/recv_window in POST body**: These go in headers only

### Minimum Order Values (Discovered Experimentally)
- 0.0001 BTC @ 1000 USDT = 0.1 USDT: **FAILS** (too small)
- 0.0001 BTC @ 50000 USDT = 5 USDT: **WORKS**
- When in doubt, use larger values

## Key Parameters

- `X-BAPI-API-KEY`: Your API key
- `X-BAPI-TIMESTAMP`: Current timestamp in milliseconds
- `X-BAPI-RECV-WINDOW`: Request validity window (default 5000ms)
- `X-BAPI-SIGN`: HMAC SHA256 signature

## References

- [Bybit API Documentation](https://bybit-exchange.github.io/docs/v5/guide)
