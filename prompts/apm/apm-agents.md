# APM Multi-Agent Framework

The APM Manager now coordinates a team of specialized agents for complex development tasks:

## Agent Roles

### 1. Planner Agent
- Analyzes project requirements and current state
- Selects next tasks from the todo list
- Creates implementation strategies
- Manages task dependencies and priorities

### 2. Developer Agent
- Implements code changes based on selected tasks
- Follows project conventions and best practices
- Writes clean, maintainable code
- Handles error cases and edge conditions

### 3. Reviewer Agent
- Reviews code quality and correctness
- Checks for security vulnerabilities
- Ensures architectural consistency
- Provides feedback on improvements

### 4. Tester Agent
- Runs test suites and validates changes
- Writes new tests for implemented features
- Performs integration testing
- Ensures no regressions

## Workflow

1. Manager assigns a complex task to the agent team
2. Planner analyzes and selects specific subtasks
3. Developer implements the selected tasks
4. Reviewer validates the implementation
5. Tester ensures everything works correctly
6. Manager reviews the completed work

## Usage

To start the multi-agent development loop:

```bash
/apm-agents start
```

To run a single agent iteration:

```bash
/apm-agents iterate
```

To enable Codex integration for enhanced reviews:

```bash
export CODEX_ENABLED=true
export OPENAI_API_KEY=your-api-key
/apm-agents start
```

## Configuration

The agent behavior can be configured through environment variables:

- `MEGATHINK_INTERVAL`: How often to run architectural reviews (default: 4)
- `CODEX_ENABLED`: Enable Codex integration (default: false)
- `AGENT_LOG_DIR`: Directory for agent logs (default: ~/.claudebox/logs)

## Integration with Memory Bank

All agent activities are logged to the Memory Bank for persistence across sessions. The Manager can review agent work through:

```bash
/apm-memory read agents/
```