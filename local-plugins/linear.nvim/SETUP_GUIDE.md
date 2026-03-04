# Linear.nvim Setup Guide

## Step 1: Get Your Linear API Key

1. Go to: **https://linear.app/settings/api**
2. Click "Create new key" or use an existing one
3. Copy the key (starts with `lin_api_`)

## Step 2: Set Environment Variable

Add to your shell configuration file:

**For Zsh** (`~/.zshrc`):
```bash
export LINEAR_API_KEY="lin_api_xxxxx"
```

**For Bash** (`~/.bashrc` or `~/.bash_profile`):
```bash
export LINEAR_API_KEY="lin_api_xxxxx"
```

**For Fish** (`~/.config/fish/config.fish`):
```fish
set -x LINEAR_API_KEY "lin_api_xxxxx"
```

**For Nushell** (`~/.config/nushell/env.nu`):
```nu
$env.LINEAR_API_KEY = "lin_api_xxxxx"
```

## Step 3: Reload Your Shell

```bash
# For zsh/bash
source ~/.zshrc  # or ~/.bashrc

# Or just restart your terminal
```

## Step 4: Verify Setup

```bash
echo $LINEAR_API_KEY
# Should print: lin_api_xxxxx
```

## Step 5: Test in Neovim

Open Neovim from the same terminal where you set the variable:

```vim
:Linear test-auth
```

Expected output: "✓ Authenticated as: Your Name (your@email.com)"

## Alternative: Temporary Setup (For Testing)

If you just want to test without permanently setting the variable:

```bash
export LINEAR_API_KEY="lin_api_xxxxx"
nvim
```

This will only last for the current terminal session.

## Troubleshooting

### "LINEAR_API_KEY environment variable not set"

- Make sure you reloaded your shell config
- Make sure you opened Neovim from a terminal where the variable is set
- Try `echo $LINEAR_API_KEY` in the terminal before opening Neovim

### "Authentication failed: HTTP request failed"

- Check your internet connection
- Verify the API key is correct
- Make sure `curl` is installed (`which curl`)

### "GraphQL error: Invalid API key"

- Your API key may be expired or revoked
- Generate a new key from Linear settings

## Security Note

**Never commit your API key to version control!**

The key is stored in your shell config (not in the Neovim plugin), so it won't be accidentally committed with your dotfiles if you're careful.

Consider using a secrets manager or `.env` file that's gitignored if sharing your config.
