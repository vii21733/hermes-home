# Himalaya Configuration Reference

Configuration file location: `~/.config/himalaya/config.toml`

## Minimal IMAP + SMTP Setup

```toml
[accounts.default]
email = "user@example.com"
display-name = "Your Name"
default = true

# IMAP backend for reading emails
backend.type = "imap"
backend.host = "imap.example.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "user@example.com"
backend.auth.type = "password"
backend.auth.raw = "your-password"

# SMTP backend for sending emails
message.send.backend.type = "smtp"
message.send.backend.host = "smtp.example.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "user@example.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.raw = "your-password"
```

## Password Options

### Raw password (testing only, not recommended)

```toml
backend.auth.raw = "your-password"
```

### Password from command (recommended)

```toml
backend.auth.cmd = "pass show email/imap"
# backend.auth.cmd = "security find-generic-password -a user@example.com -s imap -w"
```

### System keyring (requires keyring feature)

```toml
backend.auth.keyring = "imap-example"
```

Then run `himalaya account configure <account>` to store the password.

## Gmail Configuration

```toml
[accounts.gmail]
email = "you@gmail.com"
display-name = "Your Name"
default = true

backend.type = "imap"
backend.host = "imap.gmail.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@gmail.com"
backend.auth.type = "password"
backend.auth.cmd = "pass show google/app-password"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.gmail.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "you@gmail.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show google/app-password"
```

### Gmail Authentication Troubleshooting

**Problem:** `AUTHENTICATIONFAILED Invalid credentials` even with correct password.

**Root Cause:** Gmail blocks regular passwords for IMAP/SMTP. Requires **App Password**.

**CRITICAL PREREQUISITE:** If "App Passwords" setting is "not available" in your Google Account, you **MUST enable 2-Step Verification FIRST** before App Passwords will appear.

**The Fix (3 Steps):**

1. **Enable 2-Step Verification** (REQUIRED - App Passwords won't show without this)
 - Go to: https://myaccount.google.com/signinoptions/two-step-verification
 - Click "Get started"
 - Add your phone number for SMS/call verification
 - Complete the setup wizard
 - **IMPORTANT:** Once 2FA is enabled, the "App passwords" option WILL appear in your account

2. **Generate App Password**
 - Go to: https://myaccount.google.com/apppasswords 
 - Select app: "Mail"
 - Select device: "Other" (name it "Hermes" or "CLI")
 - Click "Generate" → Copy the 16-character code (e.g., `abcd efgh ijkl mnop`)

3. **Update Config with App Password**

```toml
[accounts.gmail]
email = "you@gmail.com"
display-name = "Your Name"
default = true

backend.type = "imap"
backend.host = "imap.gmail.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@gmail.com"
backend.auth.type = "password"
backend.auth.raw = "YOUR_16_CHAR_APP_PASSWORD"  # NOT your regular password!

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.gmail.com"
message.send.backend.port = 587
backend.encryption.type = "start-tls"
message.send.backend.login = "you@gmail.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.raw = "YOUR_16_CHAR_APP_PASSWORD"
```

**Security Note:** Store App Passwords securely using `pass` or keyring instead of `raw`:
```toml
backend.auth.cmd = "pass show email/gmail-app-password"
```

**Common Errors & Solutions:**

| Error | Meaning | Fix |
|-------|---------|-----|
| `AUTHENTICATIONFAILED Invalid credentials` | Using regular password | Use 16-char App Password |
| `App Passwords setting not available` | 2FA not enabled | Enable 2-Step Verification first |
| `Less secure apps not available` | Account has modern security | Use App Password method |
| "This browser or app may not be secure" | Bot detection triggered | Use IMAP + App Password instead of browser login |
| "Settings is not available" (in Gmail) | 2FA prerequisite not met | Complete step 1 above |

**What Does NOT Work for Gmail:**
- ❌ Regular Gmail password (blocked for IMAP/SMTP)
- ❌ "Less secure apps" toggle (deprecated/unavailable for new accounts)
- ❌ Browser automation (Google detects and blocks)
- ❌ Direct OAuth2 without Google Cloud project (requires console setup)

**What DOES Work:**
- ✅ **App Password** (after enabling 2FA) - Fastest, most reliable
- ✅ **Google Workspace API** (via `google-workspace` skill) - Requires OAuth setup

**Recommendation:** Use App Password method for immediate access. It's the only method that doesn't require Google Cloud Console setup.

## iCloud Configuration

```toml
[accounts.icloud]
email = "you@icloud.com"
display-name = "Your Name"

backend.type = "imap"
backend.host = "imap.mail.me.com"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "you@icloud.com"
backend.auth.type = "password"
backend.auth.cmd = "pass show icloud/app-password"

message.send.backend.type = "smtp"
message.send.backend.host = "smtp.mail.me.com"
message.send.backend.port = 587
message.send.backend.encryption.type = "start-tls"
message.send.backend.login = "you@icloud.com"
message.send.backend.auth.type = "password"
message.send.backend.auth.cmd = "pass show icloud/app-password"
```

**Note:** Generate an app-specific password at appleid.apple.com

## Folder Aliases

Map custom folder names:

```toml
[accounts.default.folder.alias]
inbox = "INBOX"
sent = "Sent"
drafts = "Drafts"
trash = "Trash"
```

## Multiple Accounts

```toml
[accounts.personal]
email = "personal@example.com"
default = true
# ... backend config ...

[accounts.work]
email = "work@company.com"
# ... backend config ...
```

Switch accounts with `--account`:

```bash
himalaya --account work envelope list
```

## Notmuch Backend (local mail)

```toml
[accounts.local]
email = "user@example.com"

backend.type = "notmuch"
backend.db-path = "~/.mail/.notmuch"
```

## OAuth2 Authentication (for providers that support it)

```toml
backend.auth.type = "oauth2"
backend.auth.client-id = "your-client-id"
backend.auth.client-secret.cmd = "pass show oauth/client-secret"
backend.auth.access-token.cmd = "pass show oauth/access-token"
backend.auth.refresh-token.cmd = "pass show oauth/refresh-token"
backend.auth.auth-url = "https://provider.com/oauth/authorize"
backend.auth.token-url = "https://provider.com/oauth/token"
```

## Additional Options

### Signature

```toml
[accounts.default]
signature = "Best regards,\nYour Name"
signature-delim = "-- \n"
```

### Downloads directory

```toml
[accounts.default]
downloads-dir = "~/Downloads/himalaya"
```

### Editor for composing

Set via environment variable:

```bash
export EDITOR="vim"
```
