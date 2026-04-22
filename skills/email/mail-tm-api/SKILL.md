---
name: mail-tm-api
description: Create and manage temporary email accounts via Mail.tm API. Fast alternative when Gmail/App Passwords are unavailable. Supports account creation, authentication, token refresh, and message retrieval via REST API.
version: 1.0.0
author: jezyAi
license: MIT
metadata:
  hermes:
    tags: [Email, Temporary, API, Mail.tm, Disposable]
    homepage: https://api.mail.tm/
---

# Mail.tm API Email

Temporary email service with full API access. Use when Gmail/App Passwords are unavailable or when you need quick anonymous email without phone verification.

## When to Use This

- **Gmail blocked:** App Passwords setting unavailable, OAuth requires Cloud Console setup
- **Quick setup:** No phone verification, no waiting, instant activation  
- **API access:** Programmatic email checking via REST API
- **Anonymous:** No personal info required

## Quick Start

```bash
# 1. Create account (generates random address)
# POST https://api.mail.tm/accounts
# Body: {"address": "unique@domain.com", "password": "YourPass123!"}

# 2. Get auth token
# POST https://api.mail.tm/token
# Body: {"address": "unique@domain.com", "password": "YourPass123!"}

# 3. Check messages
# GET https://api.mail.tm/messages
# Header: Authorization: Bearer TOKEN
```

## Full Workflow

### Create Account

```bash
EMAIL="jezy-$(date +%s)@deltajohnsons.com"
PASSWORD="SecurePass123!"

# Create via terminal command:
terminal(command="curl -s -X POST https://api.mail.tm/accounts -H 'Content-Type: application/json' -d '{\"address\":\"YOUR_EMAIL\",\"password\":\"YOUR_PASSWORD\"}'")

# Response contains:
# - id: Account ID
# - address: Your email address
# - quota: 40000000 (40MB)
```

### Authenticate

```bash
# Get token (valid for ~30 minutes)
terminal(command="curl -s -X POST https://api.mail.tm/token -H 'Content-Type: application/json' -d '{\"address\":\"YOUR_EMAIL\",\"password\":\"YOUR_PASSWORD\"}'")

# Response contains:
# - token: JWT token for API calls
```

### Check Inbox

```bash
# List messages
terminal(command="curl -s -X GET https://api.mail.tm/messages -H 'Authorization: Bearer YOUR_TOKEN'")

# Response contains:
# - hydra:totalItems: Message count
# - hydra:member: Array of messages
```

### Read Message

```bash
# Get message content
terminal(command="curl -s -X GET https://api.mail.tm/messages/MESSAGE_ID -H 'Authorization: Bearer YOUR_TOKEN'")

# Response contains:
# - from, to, subject
# - text: Plain text body
# - html: HTML body
```

## Token Refresh

**Important:** Tokens expire (~30 min). Re-authenticate to get fresh token:

```bash
# When you get "Invalid JWT Token" error, re-run the token endpoint
# The token endpoint always returns a fresh valid token
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/accounts` | POST | Create new account |
| `/accounts/{id}` | GET | Get account info |
| `/accounts/{id}` | DELETE | Delete account |
| `/me` | GET | Current account |
| `/token` | POST | Get auth token |
| `/messages` | GET | List messages |
| `/messages/{id}` | GET | Read message |
| `/messages/{id}` | DELETE | Delete message |
| `/messages/{id}/download` | GET | Download raw |

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Invalid JWT Token` | Re-authenticate to get fresh token |
| `401 Unauthorized` | Token expired, refresh it |
| `Account already exists` | Use different email address |
| `Domain not found` | Use valid domain from `/domains` endpoint |

## Available Domains

```bash
# Get list of available domains
terminal(command="curl -s -X GET https://api.mail.tm/domains")
```

Common domains:
- `deltajohnsons.com`
- Others via API

## Comparison with Gmail

| Feature | Gmail IMAP | Mail.tm API |
|---------|-----------|-------------|
| Setup time | 10-30 min (App Password) | 2 min |
| Phone required | Yes | No |
| Permanent | Yes | Temporary |
| Storage | 15GB | 40MB |
| API access | IMAP/SMTP | REST API |
| Authentication | App Password | API Token |

## Use Cases

1. **Quick verification** — Sign up for services, receive codes
2. **Anonymous testing** — Test email workflows
3. **Automation** — Receive emails via API without IMAP complexity
4. **Fallback** — When Gmail/App Passwords unavailable

## Security Notes

- Temporary emails auto-delete after inactivity
- 40MB storage quota
- Use for non-critical accounts only
- Tokens expire, refresh as needed

## References

- API Docs: https://api.mail.tm/
- Main Site: https://mail.tm/
