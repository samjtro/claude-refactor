#!/usr/bin/env bash

# Installation script for Claude Refactor
set -euo pipefail

# Color codes
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Configuration
readonly INSTALL_DIR="/usr/local/bin"
readonly SCRIPT_NAME="claude-refactor"
readonly SCRIPT_PATH="$(dirname "$0")/${SCRIPT_NAME}"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}              Claude Refactor Installation                          ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo

# Check if script exists
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo -e "${RED}Error: ${SCRIPT_NAME} not found in current directory${NC}"
    exit 1
fi

# Check for Claude Code CLI
echo -e "${BLUE}Checking dependencies...${NC}"

if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude CLI found${NC}"
elif command -v npx &> /dev/null && npx claude-code --version &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Claude Code available via npx${NC}"
else
    echo -e "${YELLOW}⚠ Claude Code CLI not found${NC}"
    echo -e "  Please install with: ${BLUE}npm install -g @anthropic-ai/claude-code${NC}"
    echo
    read -p "Continue installation anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation cancelled${NC}"
        exit 1
    fi
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠ Node.js not found${NC}"
    echo -e "  Node.js is required for Claude Code CLI"
    echo -e "  Install from: https://nodejs.org/"
    echo
fi

# Create necessary directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "$HOME/.claude-refactor"/{sessions,logs,templates}
echo -e "${GREEN}✓ Created ~/.claude-refactor directories${NC}"

# Install the CLI
echo -e "${BLUE}Installing claude-refactor...${NC}"

# Check if we need sudo
if [[ -w "$INSTALL_DIR" ]]; then
    cp "$SCRIPT_PATH" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
else
    echo -e "${YELLOW}Need sudo access to install to $INSTALL_DIR${NC}"
    sudo cp "$SCRIPT_PATH" "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
fi

echo -e "${GREEN}✓ Installed to $INSTALL_DIR/$SCRIPT_NAME${NC}"

# Create example refactor guide
echo -e "${BLUE}Creating example refactor guide...${NC}"
cat > "$HOME/.claude-refactor/templates/example-refactor-guide.md" <<'EOF'
# Example Refactor Guide

This is an example refactor guide to demonstrate the structure needed for claude-refactor.

## Overview

This refactor aims to modernize our authentication system by:
- Migrating from session-based to JWT token authentication
- Implementing refresh token rotation
- Adding multi-factor authentication support
- Improving security audit logging

## Current State

### Existing Implementation
- Session-based authentication using Express sessions
- Sessions stored in Redis
- Basic username/password authentication
- Limited security logging

### Pain Points
- Session management overhead
- Difficulty scaling horizontally
- No MFA support
- Insufficient audit trail

## Target Architecture

### Goals
1. Stateless JWT authentication
2. Secure refresh token mechanism
3. TOTP-based MFA
4. Comprehensive audit logging

### Technical Requirements
- JWT tokens with 15-minute expiry
- Refresh tokens with 7-day expiry and rotation
- TOTP support using speakeasy library
- Structured logging with correlation IDs

## Constraints

- Must maintain backward compatibility for 30 days
- Zero downtime migration
- Existing API contracts must be preserved
- Performance should not degrade

## Success Criteria

- All existing authentication flows work with JWTs
- MFA can be enabled/disabled per user
- Refresh token rotation prevents token replay attacks
- Audit logs capture all authentication events
- Load testing shows <5ms overhead vs sessions

## Implementation Preferences

- Use existing Express middleware patterns
- Leverage our current error handling framework
- Follow team's coding standards
- Comprehensive test coverage (>90%)

## Out of Scope

- OAuth/SAML integration (future phase)
- Biometric authentication
- Password policy changes

## Additional Context

- The team prefers incremental rollout
- We have a 2-week sprint for this work
- Security team must review before production
EOF

echo -e "${GREEN}✓ Created example guide at ~/.claude-refactor/templates/example-refactor-guide.md${NC}"

# Test installation
echo
echo -e "${BLUE}Testing installation...${NC}"
if command -v claude-refactor &> /dev/null; then
    echo -e "${GREEN}✓ claude-refactor is available in PATH${NC}"
    echo
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  ${YELLOW}claude-refactor start <guide.md>${NC}  - Start a new refactor"
    echo -e "  ${YELLOW}claude-refactor list${NC}              - List all sessions"
    echo -e "  ${YELLOW}claude-refactor --help${NC}            - Show help"
    echo
    echo -e "${BLUE}Example:${NC}"
    echo -e "  ${YELLOW}claude-refactor start ~/.claude-refactor/templates/example-refactor-guide.md${NC}"
else
    echo -e "${RED}⚠ claude-refactor not found in PATH${NC}"
    echo -e "  You may need to add $INSTALL_DIR to your PATH"
    echo -e "  Or run directly: ${YELLOW}$INSTALL_DIR/$SCRIPT_NAME${NC}"
fi

echo