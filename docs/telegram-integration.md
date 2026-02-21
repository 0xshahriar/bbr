# Telegram Integration Guide

Send BBR scan notifications to Telegram chats.

## Setup Instructions

### Step 1: Create Bot with BotFather

1. Open Telegram and search for **@BotFather**
2. Start chat and send: `/newbot`
3. Follow prompts:
   - Name: `BBR Scanner`
   - Username: `yourname_bbr_bot` (must end in _bot)
4. Copy the **HTTP API Token**:
   ```
   123456789:ABCdefGHIjklMNOpqrSTUvwxyz
   ```

### Step 2: Get Chat ID

#### For Personal Chat

1. Message your new bot
2. Visit:
   ```
   https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
   ```
3. Look for `"chat":{"id":123456789`
4. Copy the ID number

#### For Group Chat

1. Add bot to your group
2. Send a message in the group
3. Visit the getUpdates URL above
4. Look for `"chat":{"id":-1001234567890` (negative number)

#### For Channel

1. Add bot as admin to channel
2. Post a message
3. Check getUpdates for channel ID

### Step 3: Configure BBR

Add to your `config.yaml`:

```yaml
telegram_bot_token: "123456789:ABCdefGHIjklMNOpqrSTUvwxyz"
telegram_chat_id: "123456789"
```

Or use environment variables:

```bash
export BBR_TELEGRAM_TOKEN="123456789:ABC..."
export BBR_TELEGRAM_CHAT_ID="123456789"
```

## Testing

Send test message:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"chat_id":"YOUR_CHAT_ID","text":"BBR Test Message"}' \
  https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage
```

Run scan:

```bash
./bbr.sh -d example.com -all
```

## Message Format

BBR sends Telegram messages with:

```
🚨 BBR Alert

Target: example.com
Severity: CRITICAL
Template: CVE-2021-XXXX
URL: https://vulnerable.example.com

Time: 2024-01-15 14:30:00
```

## Customization

### Message Templates

BBR supports custom message formatting:

```yaml
# In config.yaml (if supported)
telegram_message_template: ""
  🎯 *{target}*
  ⚠️ Severity: *{severity}*
  🔍 {template}
  🌐 `{url}`
"""
```

### Notification Levels

Control which severities trigger Telegram:

```yaml
# Only critical and high
telegram_notify_severity: "critical,high"

# All severities
telegram_notify_severity: "critical,high,medium,low,info"
```

### Silent Notifications

Send silently (no sound):

```yaml
telegram_silent: true
```

## Troubleshooting

### "Bot was blocked by user"
- Start chat with bot first
- Send `/start` to bot

### "Chat not found"
- Wrong chat ID
- Bot not added to group/channel
- Use getUpdates to verify

### "Unauthorized"
- Wrong bot token
- Regenerate token with @BotFather: `/revoke`

### Messages delayed
- Telegram has rate limits
- BBR batches messages to avoid flooding

### No notifications for medium/low
- Check `telegram_notify_severity` setting
- Default may only notify for critical/high

## Privacy & Security

1. **Keep token secret** - Anyone can control your bot with it
2. **Use private chats/groups** - Don't post to public channels
3. **Restrict bot permissions** - Only Send Messages
4. **Delete messages** - Use `/delete` if you leak sensitive info

## Alternative: Using Telegram CLI

For advanced users, use `telegram-cli`:

```bash
# Install
sudo apt install telegram-cli

# Configure BBR to use CLI instead of bot
# (Requires additional setup)
```

## Group vs Channel

| Feature | Group | Channel |
|---------|-------|---------|
| Members see each other | Yes | No |
| Comments | Yes | No |
| Admin-only posting | No | Yes |
| Best for | Team chat | Broadcast alerts |

**Recommendation**: Use **Channel** for alerts, **Group** for team discussion.

---

**Need help?** Join our [Telegram](https://t.me/bbr_tool) or [Discord](https://discord.gg/bbr)
