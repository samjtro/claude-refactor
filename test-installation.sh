#!/usr/bin/env bash

# Test script for Claude Refactor installation

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Testing Claude Refactor Installation..."
echo

# Test 1: Check if claude-refactor is executable
if [[ -x "./claude-refactor" ]]; then
    echo -e "${GREEN}✓${NC} claude-refactor is executable"
else
    echo -e "${RED}✗${NC} claude-refactor is not executable"
    echo "  Run: chmod +x claude-refactor"
fi

# Test 2: Check for Claude CLI
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓${NC} Claude CLI found"
elif command -v npx &> /dev/null && npx claude-code --version &> /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Claude Code available via npx"
else
    echo -e "${RED}✗${NC} Claude Code CLI not found"
    echo "  Install with: npm install -g @anthropic-ai/claude-code"
fi

# Test 3: Check for required editors
if command -v nvim &> /dev/null; then
    echo -e "${GREEN}✓${NC} Neovim found (preferred)"
elif command -v vim &> /dev/null; then
    echo -e "${GREEN}✓${NC} Vim found"
else
    echo -e "${YELLOW}⚠${NC} No vim/nvim found (optional but recommended)"
fi

# Test 4: Check help command
echo
echo "Testing help command..."
if ./claude-refactor --help &> /dev/null; then
    echo -e "${GREEN}✓${NC} Help command works"
else
    echo -e "${RED}✗${NC} Help command failed"
fi

# Test 5: Check version
if ./claude-refactor version &> /dev/null; then
    echo -e "${GREEN}✓${NC} Version command works"
else
    echo -e "${RED}✗${NC} Version command failed"
fi

echo
echo "Installation test complete!"