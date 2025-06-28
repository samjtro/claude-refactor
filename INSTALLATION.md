# Claude Refactor Installation & Setup Guide

## Quick Install

```bash
git clone https://github.com/samjtro/claude-refactor.git
cd claude-refactor
./install-claude-refactor.sh
```

## Execution Modes

Claude Refactor supports multiple execution modes to work with different authentication methods:

### 1. **Hybrid Mode** (Default - Recommended)
Works with Claude's session authentication while providing automation assistance.

```bash
claude-refactor start guide.md  # Uses hybrid mode by default
```

**How it works:**
- Launches Claude interactively but provides automation helpers
- Copies prompts to clipboard automatically
- Monitors for expected file creation
- Guides you through each phase

### 2. **Auto Mode**
Attempts full automation using various CLI features.

```bash
claude-refactor --mode auto start guide.md
# or
CLAUDE_REFACTOR_MODE=auto claude-refactor start guide.md
```

**Requirements:**
- Claude CLI must support `-p` (print) flag
- Or stdin redirection must work
- Or `expect` must be installed

### 3. **Interactive Mode**
Pure interactive mode with clear instructions at each step.

```bash
claude-refactor --mode interactive start guide.md
```

**Best for:**
- When automation isn't working
- When you want full control
- Learning the workflow

### 4. **API Mode** (Automatic if API key detected)
Uses direct API calls for fastest execution.

```bash
export ANTHROPIC_API_KEY="your-key-here"
claude-refactor start guide.md  # Automatically uses API mode
```

## Authentication Setup

### Option 1: Session Authentication (Recommended)
```bash
# Login to Claude
claude auth login

# Verify authentication
claude auth status
```

### Option 2: API Key
```bash
# Add to your shell profile
export ANTHROPIC_API_KEY="sk-ant-..."
```

## Troubleshooting Automation

If automation isn't working in your environment:

### 1. Check Claude CLI Version
```bash
claude --version
# Ensure you have the latest version
npm update -g @anthropic-ai/claude-code
```

### 2. Test Print Mode
```bash
# Test if print mode works
echo "Explain RNA" | claude -p
```

### 3. Install Expect (Optional)
For better automation support:

```bash
# macOS
brew install expect

# Ubuntu/Debian
sudo apt-get install expect

# RHEL/CentOS
sudo yum install expect
```

### 4. Use Hybrid Mode
If full automation fails, hybrid mode provides the best balance:

```bash
CLAUDE_REFACTOR_MODE=hybrid claude-refactor start guide.md
```

## Customizing Workflow

### Environment Variables
```bash
# Set default mode
export CLAUDE_REFACTOR_MODE=hybrid

# Enable debug output
export DEBUG=1

# Custom session directory
export CLAUDE_REFACTOR_DIR=~/my-refactors
```

### Config File
Edit `~/.claude-refactor/config/default.json`:

```json
{
  "models": {
    "orchestrator": "opus",
    "implementation": "sonnet-3.5"
  },
  "execution": {
    "default_mode": "hybrid",
    "clipboard_copy": true,
    "auto_monitor": true
  }
}
```

## Platform-Specific Notes

### macOS
- Clipboard copying works automatically via `pbcopy`
- File monitoring uses native FSEvents

### Linux
- Install `xclip` for clipboard support: `sudo apt-get install xclip`
- File monitoring uses inotify

### Windows (WSL)
- Use WSL2 for best compatibility
- Install `xclip` and configure X11 forwarding for clipboard

## Common Issues

### "Claude CLI not found"
```bash
npm install -g @anthropic-ai/claude-code
```

### "Authentication failed"
```bash
claude auth logout
claude auth login
```

### "Automation not working"
Try each mode in order:
1. API mode (if you have a key)
2. Auto mode (with latest CLI)
3. Hybrid mode (recommended)
4. Interactive mode (always works)

### "Files not created in artifacts/"
Ensure your prompts instruct Claude to:
- Create the `artifacts` directory
- Save files with specific names
- Use the correct working directory

## Best Practices

1. **Start with Hybrid Mode**: It provides the best balance of automation and control

2. **Use Clear Refactor Guides**: The clearer your guide, the better the results

3. **Monitor Progress**: Watch the session output to ensure tasks complete correctly

4. **Check Artifacts**: Always verify files are created in `artifacts/`

5. **Save Sessions**: All sessions are saved in `~/.claude-refactor/sessions/` for review

## Getting Help

- Check logs: `~/.claude-refactor/logs/`
- Run with debug: `DEBUG=1 claude-refactor start guide.md`
- File issues: https://github.com/samjtro/claude-refactor/issues