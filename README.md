# Claude Refactor

A powerful standalone CLI tool that orchestrates multiple Claude Code instances to manage complex codebase refactoring through an intelligent multi-agent workflow. This tool implements a sophisticated project management lifecycle combining APM (Agentic Project Management) principles with multi-agent orchestration for comprehensive refactor management.

## Overview

Claude Refactor is a command-line tool that runs **outside** of Claude Code, providing a clean interface to manage comprehensive refactoring projects. It automates the entire lifecycle from requirements gathering through implementation and review.

### Key Features

- 🤖 **Multi-Agent Orchestration**: Opus models orchestrate Sonnet instances for development
- 🎯 **Phased Workflow**: Questions → Planning → Development → Review
- 📝 **Interactive Editing**: Integrated vim/nvim support for Q&A and plan refinement
- 🔄 **Iterative Planning**: Refine plans with update loops until perfect
- 📊 **Interactive Sessions**: See Claude working in real-time, no hidden processes
- 🗂️ **Session Management**: Timestamped folders for each refactor session
- 🧪 **Automated Testing**: Full-coverage test suite generation and execution
- 🧠 **Ultrathinking**: Expert PM-level analysis at every stage

## Installation

### Prerequisites

- Node.js (for Claude Code CLI)
- Claude Code CLI or npx
- Bash shell
- Text editor (vim/nvim recommended)

### Quick Install

```bash
# Clone the repository
git clone https://github.com/samjtro/claude-refactor.git
cd claude-refactor

# Run the installation script
./install-claude-refactor.sh
```

The installer will:
- Check for dependencies
- Install `claude-refactor` to `/usr/local/bin`
- Create necessary directories
- Generate example templates

### Manual Installation

```bash
# Make the CLI executable
chmod +x claude-refactor

# Copy to your PATH
sudo cp claude-refactor /usr/local/bin/

# Create required directories
mkdir -p ~/.claude-refactor/{sessions,logs,templates}
```

## Usage

### Starting a Refactor

```bash
claude-refactor start path/to/your-refactor-guide.md
```

### Listing Sessions

```bash
claude-refactor list
```

### Command Reference

```
claude-refactor [COMMAND] [OPTIONS]

Commands:
  start <guide.md>    Start a new refactor with the specified guide
  list               List all refactor sessions
  resume <session>   Resume an interrupted session (coming soon)
  clean              Clean old sessions (coming soon)
  version            Show version information

Options:
  -h, --help         Show help message
  -d, --debug        Enable debug output
```

## Workflow Overview

### 1. Create a Refactor Guide

Create a markdown file describing your refactor goals:

```markdown
# Authentication System Refactor

## Overview
Modernize our authentication system to use JWT tokens...

## Current State
- Session-based auth
- Redis storage
- Limited scalability

## Target Architecture
- JWT tokens
- Stateless design
- MFA support

## Success Criteria
- All tests passing
- <5ms performance overhead
- Zero downtime migration
```

See `~/.claude-refactor/templates/example-refactor-guide.md` for a complete template.

### 2. Run the Refactor

```bash
claude-refactor start auth-refactor.md
```

### 3. Interactive Workflow

The CLI will guide you through:

#### Phase 1: Questions Generation
- Claude analyzes your guide
- Generates comprehensive questions
- Opens your editor for answers

#### Phase 2: Plan Creation
- Creates detailed implementation plan
- Allows iterative refinement
- Continues once you're satisfied

#### Phase 3: Development
- Breaks plan into phases
- Generates granular tasks
- Executes development with Sonnet
- Runs tests automatically

#### Phase 4: Final Review
- Comprehensive validation
- Checks against requirements
- Produces final report

### 4. Review Results

All artifacts are saved in timestamped sessions:

```
~/.claude-refactor/sessions/refactor_20241224_143022/
├── GUIDE.md              # Original refactor guide
├── artifacts/
│   ├── QUESTIONS.md      # Generated Q&A
│   ├── PLAN.md          # Final plan
│   ├── TASKS_*.md       # Phase task lists
│   └── FINAL_REVIEW.md  # Review report
├── logs/                # Execution logs
└── session.json         # Session metadata
```

## Architecture

### Design Philosophy

Claude Refactor operates as an **external orchestrator**, providing:

1. **Clean Separation**: Runs outside Claude Code for better control
2. **Model Optimization**: Uses Opus for planning, Sonnet for implementation
3. **Structured Workflow**: Enforces best practices through phases
4. **Human-in-the-Loop**: Interactive editing at key decision points
5. **Transparency**: All artifacts saved for review and audit

### Technical Details

- **Language**: Bash script for maximum compatibility
- **Claude Integration**: Uses Claude Code SDK/CLI
- **Session Storage**: File-based for simplicity and portability
- **Editor Support**: Respects `$EDITOR` environment variable

## Example Refactor Guides

### API Modernization

```markdown
# API Modernization Refactor

## Overview
Migrate from REST to GraphQL while maintaining backward compatibility...
```

### Database Migration

```markdown
# Database Migration Refactor

## Overview
Migrate from MongoDB to PostgreSQL with zero downtime...
```

### Microservices Split

```markdown
# Monolith to Microservices Refactor

## Overview
Extract authentication and user services from monolith...
```

## Troubleshooting

### Claude Code Not Found

```bash
# Install Claude Code CLI globally
npm install -g @anthropic-ai/claude-code

# Or use npx (automatically detected)
npx claude-code --version
```

### Permission Denied

```bash
# Make sure the script is executable
chmod +x /usr/local/bin/claude-refactor

# Check your PATH
echo $PATH
```

### Session Errors

Check logs in `~/.claude-refactor/logs/` for detailed error messages.

## Advanced Usage

### Debug Mode

```bash
DEBUG=1 claude-refactor start guide.md
```

### Custom Working Directory

```bash
cd /path/to/project
claude-refactor start ./docs/refactor.md
```

### Environment Variables

- `EDITOR`: Preferred text editor (default: nvim)
- `DEBUG`: Enable debug output (0 or 1)
- `CLAUDE_REFACTOR_DIR`: Custom session directory

## Contributing

Claude Refactor is part of the Claude setup repository. Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Architecture Details

### Prompt System

Claude Refactor uses a modular prompt architecture:

```
prompts/
├── apm/                     # APM framework prompts
│   ├── 00_Initial_Manager_Setup/
│   ├── 01_Manager_Agent_Core_Guides/
│   └── 02_Utility_Prompts_And_Format_Definitions/
├── agents/                  # Agent-specific prompts
│   ├── developer.md
│   ├── planner.md
│   ├── reviewer.md
│   └── tester.md
└── refactor/               # Refactor workflow prompts
    ├── questions_generator.md
    ├── plan_generator.md
    ├── task_orchestrator.md
    └── phase_reviewer.md
```

### Configuration

The system can be configured via `config/default.json`:

```json
{
  "models": {
    "orchestrator": "opus",
    "implementation": "sonnet-3.5",
    "review": "opus"
  },
  "max_turns": {
    "questions": 10,
    "plan": 10,
    "development": 20,
    "review": 15
  }
}
```

## Future Enhancements

- [ ] Session resume functionality
- [ ] Parallel phase execution
- [ ] Web UI for monitoring
- [ ] Custom model selection
- [ ] Integration with Git
- [ ] Metrics and analytics
- [ ] Plugin system
- [ ] Memory Bank persistence
- [ ] Handover protocol implementation

## License

GNU General Public License v2.0 - see [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions:
- GitHub: https://github.com/samjtro/claude-refactor
- Create an issue for bugs or feature requests