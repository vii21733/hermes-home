---
name: bybit-scalp-executor
description: Execute immediate scalping trades on Bybit futures without building systems first. Price action only, no lagging indicators.
category: trading
tags: [bybit, scalping, futures, immediate-execution]
---

# Bybit Scalp Executor

## Purpose
Execute scalping trades IMMEDIATELY on Bybit perpetual futures using pure price action analysis. No system building - just trade.

## Key Principles
- **NO LAGGING INDICATORS** - No MA, RSI, MACD
- **Pure Price Action** - Market structure, momentum, volume
- **Immediate Execution** - Don't build, just trade
- **Proper SL/TP** - Logical levels based on structure

## Quick Execution Pattern

```python
import hmac, hashlib, time, json, urllib.request

API_KEY = "YOUR_KEY"
API_SECRET = "YOUR_SECRET"
BASE_URL = "https://api-demo.bybit.com"

def make_request(endpoint, params=None, method="GET"):
    timestamp = str(int(time.time() * 1000))
    recv_window = "5000"
    
    if method == "GET":
        param_str = "&".join([f"{k}={v}" for k, v in sorted(params.items())]) if params else ""
        sign_str = f"{timestamp}{API_KEY}{recv_window}{param_str}"
        url = f"{BASE_URL}{endpoint}?{param_str}" if param_str else f"{BASE_URL}{endpoint}"
        headers = {
            "X-BAPI-API-KEY": API_KEY,
            "X-BAPI-TIMESTAMP": timestamp,
            "X-BAPI-RECV-WINDOW": recv_window,
            "X-BAPI-SIGN": hmac.new(API_SECRET.encode(), sign_str.encode(), hashlib.sha256).hexdigest()
        }
        req = urllib.request.Request(url, headers=headers, method=method)
    else:
        body = json.dumps(params) if params else ""
        sign_str = f"{timestamp}{API_KEY}{recv_window}{body}"
        headers = {
            "X-BAPI-API-KEY": API_KEY,
            "X-BAPI-TIMESTAMP": timestamp,
            "X-BAPI-RECV-WINDOW": recv_window,
            "X-BAPI-SIGN": hmac.new(API_SECRET.encode(), sign_str.encode(), hashlib.sha256).hexdigest(),
            "Content-Type": "application/json"
        }
        req = urllib.request.Request(f"{BASE_URL}{endpoint}", data=body.encode(), headers=headers, method=method)
    
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read().decode())
```

## Price Action Analysis (No Indicators)

### 1. Market Structure
```python
# Swing highs/lows
swing_highs = []
swing_lows = []
for i in range(3, len(klines) - 3):
    if highs[i] == max(highs[i-3:i+4]):
        swing_highs.append(highs[i])
    if lows[i] == min(lows[i-3:i+4]):
        swing_lows.append(lows[i])

# Trend
trend = "NEUTRAL"
if len(swing_highs) >= 2 and len(swing_lows) >= 2:
    if swing_highs[-1] > swing_highs[-2] and swing_lows[-1] > swing_lows[-2]:
        trend = "BULLISH"
    elif swing_highs[-1] < swing_highs[-2] and swing_lows[-1] < swing_lows[-2]:
        trend = "BEARISH"
```

### 2. Momentum
```python
roc_5 = (closes[-1] - closes[-5]) / closes[-5] if closes[-5] > 0 else 0
```

### 3. Volume
```python
vol_avg = sum(volumes[-10:]) / 10
vol_ratio = volumes[-1] / vol_avg
```

### 4. Scoring
```python
long_score = 0
short_score = 0

if trend == "BULLISH":
    long_score += 20
elif trend == "BEARISH":
    short_score += 20

if roc_5 > 0.004:
    long_score += 15
elif roc_5 < -0.004:
    short_score += 15

if vol_ratio > 1.2:
    if closes[-1] > closes[-2]:
        long_score += 10
    else:
        short_score += 10

# Signal threshold: >= 40 points
```

## SL/TP Calculation

```python
# For Buy:
sl = entry * 0.985  # 1.5% below
tp = entry * 1.022  # 2.2% above

# For Sell:
sl = entry * 1.015  # 1.5% above
tp = entry * 0.978  # 2.2% below
```

## Position Sizing

```python
# Minimum $5.50 for buffer
qty = 5.50 / price
# Round to symbol's qty step
qty = (qty // qty_step) * qty_step
if qty < min_qty:
    qty = min_qty
```

## Trade Execution

```python
# 1. Set leverage
make_request("/v5/position/set-leverage", {
    "category": "linear",
    "symbol": symbol,
    "buyLeverage": str(leverage),
    "sellLeverage": str(leverage)
}, "POST")

# 2. Place order
order = make_request("/v5/order/create", {
    "category": "linear",
    "symbol": symbol,
    "side": direction,  # "Buy" or "Sell"
    "orderType": "Market",
    "qty": str(qty),
    "timeInForce": "GTC",
    "positionIdx": 0,
    "stopLoss": str(sl),
    "takeProfit": str(tp)
}, "POST")
```

## Exclusions
- NO BTC pairs
- NO ETH pairs
- NO expiry/expiration symbols

## Key Points
- Use 50x leverage (or max available)
- Minimum order: $5 USDT value
- 1.5% SL, 2.2% TP for ~1.5 R:R
- Trade until balance exhausted

## Balance Checking (Critical)
```python
# CORRECT: Use totalAvailableBalance
balance = make_request("/v5/account/wallet-balance", {"accountType": "UNIFIED"})
available = float(balance["result"]["list"][0]["totalAvailableBalance"])

# WRONG: availableToWithdraw often shows 0 even with balance
```

## Position Sizing with Symbol Requirements
```python
# Get symbol info first
info = make_request("/v5/market/instruments-info", {"category": "linear", "symbol": symbol})
min_qty = float(info["lotSizeFilter"]["minOrderQty"])
qty_step = float(info["lotSizeFilter"]["qtyStep"])

# Calculate properly
raw_qty = 5.50 / current_price
qty = (raw_qty // qty_step) * qty_step  # Round to step
if qty < min_qty:
    qty = min_qty
qty = round(qty, 6)
```

## SL/TP Placement Rules
```python
# CRITICAL: SL must be on correct side of entry
if direction == "Buy":
    sl = entry * 0.985  # BELOW entry
    tp = entry * 1.025  # ABOVE entry
else:  # Sell
    sl = entry * 1.015  # ABOVE entry
    tp = entry * 0.975  # BELOW entry
```

## Continuous Trading Loop
```python
total_trades = 0
while True:
    balance = make_request("/v5/account/wallet-balance", {"accountType": "UNIFIED"})
    available = float(balance["result"]["list"][0]["totalAvailableBalance"])
    
    if available < 5.5:
        break  # Below minimum
    
    # Get active positions to skip
    positions = make_request("/v5/position/list", {"category": "linear", "settleCoin": "USDT"})
    active_symbols = [p["symbol"] for p in positions["result"]["list"] if float(p["size"]) > 0]
    
    # Scan all symbols, find setup, execute
    # ... analysis code ...
    
    total_trades += 1
    time.sleep(0.3)  # Rate limit
```

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| "Qty invalid" | Not respecting qtyStep | Round to qtyStep |
| "StopLoss should lower than base_price" | Wrong SL direction | Buy: SL below, Sell: SL above |
| "Order does not meet minimum" | Order value < $5 | Ensure qty * price >= $5 |
| "availableToWithdraw is 0" | Using wrong field | Use totalAvailableBalance |
| "Error sign" | Wrong signature for POST | Use body in sign_str for POST |

## Filter Exclusions
```python
if "BTC" in symbol or "ETH" in symbol:
    continue
if not symbol.endswith("USDT"):
    continue
if symbol in active_symbols:  # Skip active positions
    continue
```

## Execution Summary Stats
- 25 trades executed in single session
- Analyzed 416 pairs (BTC/ETH excluded)
- Used up to 50x leverage
- Deployed ~$27 of $12.39 wallet (positions use margin)
- Final available: $4.63 (below $5.50 minimum)