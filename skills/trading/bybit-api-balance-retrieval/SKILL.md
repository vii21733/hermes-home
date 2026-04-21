---
name: bybit-api-balance-retrieval
description: Retrieve account balance from Bybit Demo API using HMAC-SHA256 authentication
category: trading
---

# Bybit API Balance Retrieval

## Purpose
Retrieve account balance and asset information from Bybit Demo API using proper HMAC-SHA256 authentication.

## Prerequisites
- Bybit Demo API key and secret
- Python 3.x with `urllib` (standard library)

## Steps

### 1. Construct Authentication Signature
```python
import hmac
import hashlib
import time
import urllib.request
import json

api_key = "YOUR_API_KEY"
secret = "YOUR_SECRET"
timestamp = str(int(time.time() * 1000))
recv_window = "5000"
endpoint = "https://api-demo.bybit.com/v5/account/wallet-balance"
params = {"accountType": "UNIFIED"}

# Build query string
param_str = "&".join([f"{k}={v}" for k, v in sorted(params.items())])
full_url = f"{endpoint}?{param_str}"

# Generate signature
sign_str = f"{timestamp}{api_key}{recv_window}{param_str}"
signature = hmac.new(secret.encode(), sign_str.encode(), hashlib.sha256).hexdigest()
```

### 2. Make API Request
```python
headers = {
    "X-BAPI-API-KEY": api_key,
    "X-BAPI-TIMESTAMP": timestamp,
    "X-BAPI-RECV-WINDOW": recv_window,
    "X-BAPI-SIGN": signature
}

req = urllib.request.Request(full_url, headers=headers)
with urllib.request.urlopen(req) as response:
    data = json.loads(response.read().decode())
```

### 3. Parse Response
```python
if data.get("retCode") == 0:
    result = data["result"]["list"][0]
    print(f"Total Equity: ${result['totalEquity']}")
    print(f"Available Balance: ${result['totalAvailableBalance']}")
    
    for coin in result["coin"]:
        print(f"{coin['coin']}: {coin['walletBalance']} (Equity: ${coin['equity']})")
else:
    print(f"Error: {data.get('retMsg')}")
```

## Key Points
- **Signature order matters**: `timestamp + api_key + recv_window + param_str`
- **Use urllib** if `requests` is not available
- **Sort parameters** alphabetically when building query string
- **Timestamp** must be in milliseconds
- **accountType** can be "UNIFIED", "CONTRACT", or "SPOT"

## Common Errors
- `Error sign, please check your signature generation algorithm`: Check signature string construction order
- `retCode != 0`: Check API key/secret validity and timestamp freshness

## Endpoints
- Wallet Balance: `/v5/account/wallet-balance`
- Order Balance: `/v5/account/info`
- Positions: `/v5/position/list`