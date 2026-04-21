---
name: hermes-model-picker-pagination
title: Fix Hermes Model Picker Pagination Limits
description: When /model command only shows a limited number of models (e.g., "1-8 of 9") despite having many models configured, this skill guides fixing the pagination limits in multiple files.
tags: [hermes, model-picker, pagination, telegram, discord, troubleshooting]
---

# Fix Model Picker Showing Limited Models

## Problem
When running `/model` command, you see a message like "1-8 of 9" or only 5 models displayed, even though you've configured many more models in `hermes_cli/models.py`.

## Root Cause
The model picker has **multiple hardcoded pagination limits** in different files:

| File | Variable | Default | Platform |
|------|----------|---------|----------|
| `gateway/platforms/telegram.py` | `_MODEL_PAGE_SIZE` | 8 | Telegram inline keyboards |
| `gateway/run.py` | `max_models=5` | 5 | Text fallback (Slack, etc.) |
| `gateway/platforms/discord.py` | `[:25]` | 25 | Discord select menus (API limit) |

## Solution

### Step 1: Fix Telegram Pagination
**File**: `gateway/platforms/telegram.py`

Find:
```python
_MODEL_PAGE_SIZE = 8
```

Change to:
```python
_MODEL_PAGE_SIZE = 50  # Or your preferred limit
```

### Step 2: Fix Text Fallback Pagination
**File**: `gateway/run.py`

Find (around line 5396):
```python
providers = list_authenticated_providers(
    current_provider=current_provider,
    user_providers=user_provs,
    custom_providers=custom_provs,
    max_models=5,
)
```

Change to:
```python
providers = list_authenticated_providers(
    current_provider=current_provider,
    user_providers=user_provs,
    custom_providers=custom_provs,
    max_models=50,  # Or your preferred limit
)
```

### Step 3: Check Discord (Optional)
**File**: `gateway/platforms/discord.py`

Discord has a hard API limit of 25 items in select menus. The code at line 3555 shows:
```python
for model_id in models[:25]:
```

This **cannot be increased** due to Discord API limitations. The UI will show:
> "*X more available — type `/model <name>` directly*"

## Verification
After making changes, restart Hermes and run `/model` again. You should see:
- **Telegram**: Up to 50 models displayed (or your configured limit)
- **Discord**: Still limited to 25 (API restriction)
- **Other platforms**: Up to 50 models displayed

## Important Notes

### Why Different Limits?
- **Telegram inline keyboards**: Can handle many buttons, limited by message size
- **Discord select menus**: Hard API limit of 25 options
- **Text platforms**: No real limit, but large lists can be unwieldy

### Maximum Practical Limits
| Platform | Recommended Max | Reason |
|----------|----------------|--------|
| Telegram | 50-100 | Message can become very long |
| Discord | 25 | API limit - cannot increase |
| Text/Slack | 50 | Readability |

## Related Files
- `hermes_cli/models.py` - Where models are defined
- `hermes_cli/model_switch.py` - `list_authenticated_providers()` function
- `gateway/platforms/telegram.py` - Telegram-specific picker
- `gateway/platforms/discord.py` - Discord-specific picker
- `gateway/run.py` - Generic text fallback

## Troubleshooting

If models still don't appear:
1. Check `hermes_cli/models.py` - Ensure models are in `_PROVIDER_MODELS["nvidia"]` (or appropriate provider)
2. Verify API keys are set - Only providers with credentials show up
3. Check provider authentication - Run `hermes doctor` to verify
4. Restart Hermes - Configuration changes require restart

## References
- Discord API: Select menus limited to 25 options
- Telegram Bot API: No hard limit, but practical limit around 100 buttons