#!/usr/bin/env bash

# Claude Hybrid Executor
# Provides multiple execution strategies based on user preference and auth method

set -euo pipefail

# Source directory for this script
HYBRID_EXECUTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execution modes
readonly MODE_AUTO="auto"          # Try automated approaches
readonly MODE_INTERACTIVE="interactive"  # Full interactive with guidance
readonly MODE_HYBRID="hybrid"      # Interactive with automation helpers
readonly MODE_API="api"           # Direct API (requires API key)

# Define log function if not already defined
if ! type -t log &> /dev/null; then
    log() {
        local level="$1"
        shift
        echo "[$level] $*" >&2
    }
fi

# Determine best execution mode
determine_execution_mode() {
    local preferred_mode="${1:-auto}"
    
    # Check if claude CLI is authenticated FIRST (prioritize login over API key)
    if command -v claude &> /dev/null; then
        if claude auth status &>/dev/null; then
            # Session auth is available, use preferred mode
            log "DEBUG" "Claude CLI authenticated, using mode: $preferred_mode"
            echo "$preferred_mode"
            return 0
        fi
    fi
    
    # Check if API key is available as fallback
    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        # Check if it looks like a valid API key (starts with sk-)
        if [[ "$ANTHROPIC_API_KEY" =~ ^sk- ]]; then
            log "WARN" "Claude CLI not authenticated, but API key found. Using API mode."
            log "WARN" "For better experience, run: claude auth login"
            echo "api"
            return 0
        else
            log "WARN" "ANTHROPIC_API_KEY is set but appears invalid (should start with 'sk-')"
            log "WARN" "Falling back to interactive mode"
        fi
    fi
    
    # Fallback to interactive
    log "DEBUG" "No authentication found, using interactive mode"
    echo "interactive"
}

# Execute with appropriate strategy
execute_claude_smart() {
    local task_name="$1"
    local prompt_file="$2"
    local working_dir="$3"
    local model="${4:-opus}"
    local expected_output="${5:-}"
    
    local mode=$(determine_execution_mode "${CLAUDE_REFACTOR_MODE:-auto}")
    
    echo "Executing task: $task_name"
    echo "Mode: $mode"
    
    case "$mode" in
        "api")
            execute_with_api "$prompt_file" "$working_dir" "$model" "$expected_output"
            ;;
        "auto")
            execute_with_automation "$prompt_file" "$working_dir" "$model" "$expected_output"
            ;;
        "hybrid")
            execute_with_hybrid "$prompt_file" "$working_dir" "$model" "$expected_output"
            ;;
        "interactive")
            execute_with_interactive "$prompt_file" "$working_dir" "$model" "$expected_output"
            ;;
    esac
}

# API-based execution (fastest, requires API key)
execute_with_api() {
    local prompt_file="$1"
    local working_dir="$2"
    local model="$3"
    local expected_output="$4"
    
    log "DEBUG" "Executing with API mode"
    
    # This would use the Anthropic API directly
    # For now, we'll use the CLI with API key
    cd "$working_dir"
    local prompt_content=$(cat "$prompt_file")
    
    # Execute claude and capture both stdout and stderr
    if claude --model "$model" -p "$prompt_content" > ".claude_output.txt" 2>&1; then
        log "DEBUG" "Claude execution completed"
        
        # Check for API key errors in output
        if grep -q "Invalid API key" ".claude_output.txt"; then
            log "ERROR" "Invalid API key detected"
            log "ERROR" "Please check your ANTHROPIC_API_KEY environment variable"
            return 1
        fi
        
        # Parse output
        parse_api_output ".claude_output.txt" "$working_dir"
        
        # Check for expected output
        if [[ -n "$expected_output" ]] && [[ -f "artifacts/$expected_output" ]]; then
            echo "✓ Successfully created $expected_output"
            return 0
        else
            log "ERROR" "Expected output not created: $expected_output"
            log "DEBUG" "Claude output saved to: $working_dir/.claude_output.txt"
            return 1
        fi
    else
        log "ERROR" "Claude execution failed"
        log "DEBUG" "Error output saved to: $working_dir/.claude_output.txt"
        return 1
    fi
}

# Automated execution with session auth
execute_with_automation() {
    local prompt_file="$1"
    local working_dir="$2"
    local model="$3"
    local expected_output="$4"
    
    cd "$working_dir"
    
    # Create automation-friendly prompt
    local auto_prompt_file=".auto_prompt.txt"
    create_automation_prompt "$prompt_file" "$expected_output" > "$auto_prompt_file"
    
    # Try various automation approaches
    local success=false
    
    # Approach 1: Print mode with structured output
    if try_print_mode "$auto_prompt_file" "$model"; then
        success=true
    # Approach 2: Stdin with markers
    elif try_stdin_mode "$auto_prompt_file" "$model"; then
        success=true
    # Approach 3: Expect script
    elif try_expect_mode "$auto_prompt_file" "$model"; then
        success=true
    fi
    
    if [[ "$success" == true ]]; then
        # Parse output and check for expected files
        parse_automation_output "$working_dir"
        
        if [[ -n "$expected_output" ]] && [[ -f "artifacts/$expected_output" ]]; then
            echo "✓ Successfully created $expected_output"
            return 0
        fi
    else
        echo "⚠️  Automation failed, falling back to hybrid mode"
        execute_with_hybrid "$prompt_file" "$working_dir" "$model" "$expected_output"
    fi
}

# Hybrid execution - interactive with automation assists
execute_with_hybrid() {
    local prompt_file="$1"
    local working_dir="$2"
    local model="$3"
    local expected_output="$4"
    
    cd "$working_dir"
    
    # Create a watcher script that monitors for expected output
    create_output_watcher "$expected_output" &
    local watcher_pid=$!
    
    # Create instruction file for user
    cat > ".hybrid_instructions.txt" <<EOF
=== CLAUDE HYBRID EXECUTION MODE ===

This task requires: $expected_output

When Claude opens:
1. The prompt will be automatically copied to your clipboard (if supported)
2. Paste the prompt into Claude
3. Let Claude complete the task
4. The system will detect when the expected output is created
5. Exit Claude when done (Ctrl+D)

Expected output: artifacts/$expected_output

Press Enter to copy prompt and launch Claude...
EOF
    
    cat ".hybrid_instructions.txt"
    read -r
    
    # Try to copy to clipboard
    if command -v pbcopy &> /dev/null; then
        cat "$prompt_file" | pbcopy
        echo "✓ Prompt copied to clipboard"
    elif command -v xclip &> /dev/null; then
        cat "$prompt_file" | xclip -selection clipboard
        echo "✓ Prompt copied to clipboard"
    else
        echo "⚠️  Could not copy to clipboard. Please copy manually:"
        echo "---"
        cat "$prompt_file"
        echo "---"
    fi
    
    # Launch Claude
    if command -v claude &> /dev/null; then
        claude --model "$model"
    else
        npx claude-code --model "$model"
    fi
    
    # Stop watcher
    kill $watcher_pid 2>/dev/null || true
    
    # Check if expected output was created
    if [[ -n "$expected_output" ]] && [[ -f "artifacts/$expected_output" ]]; then
        echo "✓ Successfully created $expected_output"
        return 0
    else
        echo "⚠️  Expected output not found. Please check manually."
        return 1
    fi
}

# Pure interactive mode with clear instructions
execute_with_interactive() {
    local prompt_file="$1"
    local working_dir="$2"
    local model="$3"
    local expected_output="$4"
    
    cd "$working_dir"
    
    cat > ".interactive_guide.txt" <<EOF
=== INTERACTIVE CLAUDE SESSION ===

Task: Create $expected_output

Instructions:
1. Claude will open in interactive mode
2. Copy and paste the provided prompt
3. Ensure Claude creates the file in artifacts/
4. Exit when complete

The prompt is saved in: $prompt_file

Would you like to:
1) View the prompt first
2) Launch Claude directly
3) Cancel

Choice (1-3): 
EOF
    
    cat ".interactive_guide.txt"
    read -r choice
    
    case "$choice" in
        1)
            echo "=== PROMPT ==="
            cat "$prompt_file"
            echo "=== END PROMPT ==="
            echo ""
            echo "Press Enter to launch Claude..."
            read -r
            ;;
        3)
            echo "Cancelled"
            return 1
            ;;
    esac
    
    # Launch Claude
    if command -v claude &> /dev/null; then
        claude --model "$model"
    else
        npx claude-code --model "$model"
    fi
    
    # Check result
    if [[ -n "$expected_output" ]] && [[ -f "artifacts/$expected_output" ]]; then
        echo "✓ Successfully created $expected_output"
        return 0
    else
        echo "Please ensure $expected_output was created in artifacts/"
        return 1
    fi
}

# Helper functions

create_automation_prompt() {
    local original_prompt="$1"
    local expected_output="$2"
    
    cat <<EOF
$(cat "$original_prompt")

AUTOMATION OUTPUT FORMAT:
When creating $expected_output, use exactly this format:

===BEGIN_FILE: $expected_output===
[actual file content]
===END_FILE: $expected_output===

End with:
===TASK_COMPLETE===
EOF
}

try_print_mode() {
    local prompt_file="$1"
    local model="$2"
    
    echo "Trying print mode..."
    local prompt_content=$(cat "$prompt_file")
    
    if claude --model "$model" -p "$prompt_content" > .claude_output.txt 2>&1; then
        if grep -q "===TASK_COMPLETE===" .claude_output.txt; then
            parse_structured_output .claude_output.txt
            return 0
        fi
    fi
    return 1
}

try_stdin_mode() {
    local prompt_file="$1"
    local model="$2"
    
    echo "Trying stdin mode..."
    
    if claude --model "$model" < "$prompt_file" > .claude_output.txt 2>&1; then
        if grep -q "===TASK_COMPLETE===" .claude_output.txt; then
            parse_structured_output .claude_output.txt
            return 0
        fi
    fi
    return 1
}

try_expect_mode() {
    local prompt_file="$1"
    local model="$2"
    
    if ! command -v expect &> /dev/null; then
        return 1
    fi
    
    echo "Trying expect mode..."
    
    cat > .claude_expect.exp <<'EXPECT'
#!/usr/bin/expect -f
set timeout 300
set prompt_file [lindex $argv 0]
set model [lindex $argv 1]

spawn claude --model $model
expect ">"
send [exec cat $prompt_file]
send "\r"
expect "===TASK_COMPLETE==="
send "\004"
expect eof
EXPECT
    
    chmod +x .claude_expect.exp
    
    if expect .claude_expect.exp "$prompt_file" "$model" > .claude_output.txt 2>&1; then
        parse_structured_output .claude_output.txt
        return 0
    fi
    return 1
}

parse_structured_output() {
    local output_file="$1"
    
    # Extract files from structured output - supports multiple formats
    # Using gsub for better compatibility with BSD awk
    awk '
    BEGIN {
        collecting = 0
        filepath = ""
    }
    # Format 1: ===BEGIN_FILE: filename===
    /===BEGIN_FILE: / {
        gsub(/===BEGIN_FILE: /, "", $0)
        gsub(/===/, "", $0)
        filename = $0
        filepath = "artifacts/" filename
        system("mkdir -p artifacts")
        collecting = 1
        next
    }
    /===END_FILE: / {
        collecting = 0
        if (filepath != "") close(filepath)
        next
    }
    # Format 2: <<<CREATE_FILE: filename
    /<<<CREATE_FILE: / {
        gsub(/<<<CREATE_FILE: /, "", $0)
        filename = $0
        filepath = "artifacts/" filename
        system("mkdir -p artifacts")
        collecting = 1
        next
    }
    />>>END_FILE/ {
        collecting = 0
        if (filepath != "") close(filepath)
        next
    }
    # Format 3: ===FILE_START: filename===
    /===FILE_START: / {
        gsub(/===FILE_START: /, "", $0)
        gsub(/===/, "", $0)
        filename = $0
        filepath = "artifacts/" filename
        system("mkdir -p artifacts")
        collecting = 1
        next
    }
    /===FILE_END: / {
        collecting = 0
        if (filepath != "") close(filepath)
        next
    }
    collecting == 1 && filepath != "" {
        print >> filepath
    }
    ' "$output_file"
}

create_output_watcher() {
    local expected_file="$1"
    
    while true; do
        if [[ -f "artifacts/$expected_file" ]]; then
            echo ""
            echo "✓ Detected creation of $expected_file"
            break
        fi
        sleep 2
    done
}

parse_automation_output() {
    local working_dir="$1"
    
    # Look for various output files and parse them
    for output_file in .claude_output*.txt; do
        if [[ -f "$output_file" ]]; then
            parse_structured_output "$output_file"
        fi
    done
}

parse_api_output() {
    local output_file="$1"
    local working_dir="$2"
    
    # API output should use the same structured format
    if [[ -f "$output_file" ]]; then
        parse_structured_output "$output_file"
    else
        echo "⚠️  API output file not found: $output_file"
        return 1
    fi
}

# Export main function
export -f execute_claude_smart