# Discord Integration Guide

Send BBR scan notifications to your Discord server.

## Setup Instructions

### Step 1: Open Server Settings

1. Open your Discord server
2. Click the server name (dropdown arrow)
3. Select **Server Settings**

### Step 2: Create Webhook

1. In the left sidebar, click **Integrations**
2. Click **Webhooks**
3. Click **New Webhook**
4. Configure:
   - **Name**: "BBR Scanner"
   - **Channel**: Select where to post
   - **Avatar**: (Optional) Upload BBR logo
5. Click **Copy Webhook URL**

### Step 3: Get Webhook URL

Your webhook URL looks like:
```
https://discord.com/api/webhooks/123456789/abcdefghijklmnopqrstuvwxyz
```

### Step 4: Configure BBR

Add to your `config.yaml`:

```yaml
discord_webhook: "https://discord.com/api/webhooks/123456789/abc..."
```

Or use environment variable:

```bash
export BBR_DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
```

## Testing

Run a scan:

```bash
./bbr.sh -d example.com -all
```

Check your Discord channel for:
- Scan started embed
- Subdomain count
- Vulnerability alerts (color-coded)
- Completion summary

## Message Format

BBR sends rich embeds with:

| Severity | Color | Fields |
|----------|-------|--------|
| Critical | 🔴 Red | Template, URL, Severity |
| High | 🟠 Orange | Template, URL, Severity |
| Medium | 🟡 Yellow | Template, URL, Severity |
| Info | 🔵 Blue | Summary stats |

## Customization

### Custom Username/Avatar

Edit webhook in Discord:
1. Server Settings → Integrations → Webhooks
2. Click on your BBR webhook
3. Change name and avatar

### Different Channels

Create multiple webhooks for different channels:
- `#security-alerts` - Critical only
- `#recon-logs` - All scans
- `#bug-bounty` - Bounty targets

## Troubleshooting

### "404 Not Found"
- Webhook was deleted
- URL is malformed
- Recreate webhook

### "429 Too Many Requests"
- Discord rate limit: 5 requests per 2 seconds
- BBR handles batching automatically

### Messages not appearing
- Check webhook URL is complete
- Verify bot has permission to post
- Check channel is not read-only

### Embeds not showing
- Ensure webhook has "Embed Links" permission
- Check BBR is sending embed format (default)

## Advanced: Discord Bot (Optional)

For more control, create a bot instead of webhook:

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. New Application → "BBR Bot"
3. Bot → Add Bot
4. Copy Token
5. OAuth2 → URL Generator:
   - Scopes: `bot`
   - Bot Permissions: `Send Messages`, `Embed Links`
6. Use generated URL to invite bot

**Note**: BBR currently uses webhooks. Bot support may be added later.

## Security

1. **Treat webhook URL as password** - Anyone can post with it
2. **Regenerate if leaked** - Discord → Webhook → Copy URL (regenerates)
3. **Use specific channels** - Don't post to public channels
4. **Monitor usage** - Check webhook recent requests

---

**Need help?** Join our [Discord](https://discord.gg/bbr) or [Telegram](https://t.me/bbr_tool)
