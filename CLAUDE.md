# Claude Refactor - Project Memory

This file contains important context for Claude instances working on this project.

## Project Overview

Claude Refactor is an intelligent multi-agent refactoring system that orchestrates multiple Claude instances to manage complex codebase refactoring projects. It combines:

1. **APM (Agentic Project Management)** principles for structured project execution
2. **Multi-agent orchestration** patterns from claude-fsd/claudebox
3. **Interactive workflow** with human-in-the-loop at key decision points

## Architecture

### Core Components

1. **Main Orchestrator** (`claude-refactor`)
   - Bash script that manages the entire workflow
   - Handles session management and phase transitions
   - Launches Claude instances with appropriate prompts

2. **Prompt System** (`prompts/`)
   - `apm/` - APM framework prompts for project management
   - `agents/` - Agent-specific prompts (developer, planner, reviewer, tester)
   - `refactor/` - Workflow-specific prompts for each phase

3. **Configuration** (`config/default.json`)
   - Model selections (Opus for planning/review, Sonnet for implementation)
   - Turn limits for each phase
   - Path configurations

## Workflow Phases

1. **Questions Generation** (Opus)
   - Analyzes refactor guide
   - Generates comprehensive questions
   - User answers via editor

2. **Plan Generation** (Opus)
   - Synthesizes guide + answers
   - Creates detailed phased plan
   - Iterative refinement loop

3. **Development Lifecycle** (Opus orchestrating Sonnet)
   - Task breakdown per phase
   - Sonnet agents for implementation
   - Test suite generation
   - Phase reviews

4. **Final Review** (Opus)
   - Comprehensive validation
   - Deliverables summary
   - Pass/fail determination

## Key Design Decisions

1. **External Orchestration**: Runs outside Claude Code for better control
2. **Model Specialization**: Opus for high-level thinking, Sonnet for implementation
3. **Prompt Modularity**: External prompt files for easy customization
4. **Session Persistence**: All artifacts saved in timestamped directories
5. **Interactive Editing**: vim/nvim integration for user input

## Development Guidelines

### When Making Changes

1. **Prompts**: Edit files in `prompts/` rather than hardcoding
2. **Workflow**: Modify phase functions in `claude-refactor` script
3. **Configuration**: Update `config/default.json` for settings
4. **Documentation**: Keep README.md and this file updated

### Testing Changes

```bash
# Test with example guide
./claude-refactor start example-refactor-guide.md

# Debug mode
DEBUG=1 ./claude-refactor start guide.md

# Check session artifacts
ls -la ~/.claude-refactor/sessions/
```

### Common Commands

```bash
# Run linting (if available)
npm run lint

# Run type checking (if available) 
npm run typecheck

# Run tests (if available)
npm test
```

## Important Files

- `APM-REFACTOR-GUIDE.md` - Original vision and requirements
- `example-refactor-guide.md` - Template for users
- `install-claude-refactor.sh` - Installation script
- `LICENSE` - GPL 2.0 (not MIT!)

## Context from Migration

This project was migrated from `../claude` which contained:
- Original APM prompts from agentic-project-management
- Multi-agent prompts from claude-fsd/claudebox
- Various utility scripts and configurations

The migration consolidated and refined these into a focused refactoring tool.

## Future Enhancements

Priority items:
1. Session resume functionality
2. Memory Bank persistence across sessions
3. Handover protocol for long-running refactors
4. Git integration for automatic commits
5. Parallel phase execution

## Troubleshooting

Common issues:
1. **Prompts not found**: Check paths in script match directory structure
2. **Claude CLI errors**: Ensure proper authentication with `claude auth status`
3. **Session failures**: Check logs in `~/.claude-refactor/logs/`

## License

GNU General Public License v2.0 - maintained as requested by @samjtro