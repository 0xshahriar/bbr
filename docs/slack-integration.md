# Slack Integration Guide

Send BBR scan notifications to your Slack workspace.

## Setup Instructions

### Step 1: Create a Slack App

1. Go to [Slack API Apps](https://api.slack.com/apps)
2. Click **Create New App** → **From scratch**
3. Name it "BBR Scanner" and select your workspace
4. Click **Create App**

### Step 2: Enable Incoming Webhooks

1. In the left sidebar, click **Incoming Webhooks**
2. Toggle **Activate Incoming Webhooks** to On
3. Click **Add New Webhook to Workspace**
4. Select the channel where notifications should go
5. Click **Allow**

### Step 3: Copy Webhook URL

1. You'll see a webhook URL like:
   ```
   https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
   ```
2. Copy this URL

### Step 4: Configure BBR

Add to your `config.yaml`:

```yaml
slack_webhook: "https://hooks.slack.com/services/T00/B00/XXXX"
```

Or use environment variable:

```bash
export BBR_SLACK_WEBHOOK="https://hooks.slack.com/services/..."
```

## Testing

Run a scan to test:

```bash
./bbr.sh -d example.com -all
```

You should see notifications in your Slack channel for:
- Scan start
- Subdomain enumeration complete
- Vulnerabilities found (critical/high)
- Scan completion

## Customization

### Custom Channel

You can override the channel in the webhook URL:

```yaml
slack_webhook: "https://hooks.slack.com/services/..."
```

And set the channel in BBR settings if supported.

### Message Format

BBR sends formatted messages with:
- 🔴 Critical vulnerabilities
- 🟠 High severity findings
- 🟡 Medium severity findings
- 🟢 Scan completion

## Troubleshooting

### "invalid_auth" error
- Regenerate webhook URL
- Ensure app is installed to workspace

### No notifications
- Check webhook URL is correct
- Verify channel exists and bot has access
- Check BBR logs for errors

### Rate limiting
- Slack allows ~1 message per second
- BBR batches notifications to avoid limits

## Security Best Practices

1. **Keep webhook URL secret** - Anyone with URL can post to your channel
2. **Use environment variables** instead of hardcoding in config
3. **Rotate webhooks** periodically
4. **Restrict channel access** to security team only

## Alternative: Slack Bot Token

For advanced features, use Bot Token instead of webhook:

1. Go to **OAuth & Permissions**
2. Add scopes: `chat:write`, `chat:write.public`
3. Install app to workspace
4. Copy **Bot User OAuth Token**
5. Use token in BBR (if supported)

---

**Need help?** Join our [Telegram](https://t.me/bbr_tool) or [Discord](https://discord.gg/bbr)
