#!/usr/bin/env bash

# Claude Session Automator
# Works with Claude's session authentication to provide automated workflows

set -euo pipefail

# Create a prompt that instructs Claude to save output in a parseable format
create_structured_prompt() {
    local base_prompt="$1"
    local output_instructions="$2"
    
    cat <<EOF
$base_prompt

CRITICAL AUTOMATION INSTRUCTIONS:
To ensure this automated workflow continues correctly, you MUST follow these output conventions:

1. For any files you create, use this EXACT format:
<<<CREATE_FILE: filename.md
file content here
>>>END_FILE

2. At the end of your work, provide a status marker:
<<<STATUS: COMPLETE
- Created: [list of files]
- Summary: [what was done]
>>>END_STATUS

3. If you encounter any errors:
<<<STATUS: ERROR
- Error: [description]
>>>END_STATUS

$output_instructions
EOF
}

# Execute Claude with session auth and parse output
execute_claude_session() {
    local prompt_file="$1"
    local working_dir="$2"
    local model="${3:-opus}"
    local max_turns="${4:-10}"
    local parse_output="${5:-true}"
    
    cd "$working_dir"
    
    # Determine Claude command
    local claude_cmd
    if command -v claude &> /dev/null; then
        claude_cmd="claude"
    else
        claude_cmd="npx claude-code"
    fi
    
    # Create a unique output file
    local output_file="$working_dir/.claude_output_$(date +%s).txt"
    local status_file="$working_dir/.claude_status_$(date +%s).txt"
    
    # Try different automation approaches based on what works with session auth
    
    # Approach 1: Use print mode with full prompt
    if [[ -f "$prompt_file" ]]; then
        local prompt_content=$(cat "$prompt_file")
        
        echo "Executing Claude task (using session authentication)..."
        
        # Try print mode first
        if $claude_cmd --model "$model" --max-turns "$max_turns" -p "$prompt_content" > "$output_file" 2>&1; then
            echo "✓ Task completed using print mode"
        else
            # Approach 2: Use stdin redirection with interactive mode
            echo "Trying alternative approach with stdin..."
            if $claude_cmd --model "$model" --max-turns "$max_turns" < "$prompt_file" > "$output_file" 2>&1; then
                echo "✓ Task completed using stdin redirection"
            else
                # Approach 3: Use expect script for full automation
                if command -v expect &> /dev/null; then
                    echo "Trying expect script approach..."
                    create_expect_script "$prompt_file" "$model" "$max_turns" "$output_file"
                    if expect "$working_dir/.claude_expect.exp"; then
                        echo "✓ Task completed using expect"
                    else
                        echo "✗ All automation approaches failed"
                        return 1
                    fi
                else
                    echo "✗ Automation failed and expect not available"
                    return 1
                fi
            fi
        fi
    fi
    
    # Parse output if requested
    if [[ "$parse_output" == "true" ]] && [[ -f "$output_file" ]]; then
        parse_claude_output "$output_file" "$working_dir"
        
        # Check status
        if grep -q "<<<STATUS: COMPLETE" "$output_file"; then
            extract_status "$output_file" > "$status_file"
            cat "$status_file"
            return 0
        elif grep -q "<<<STATUS: ERROR" "$output_file"; then
            echo "Claude reported an error:"
            extract_status "$output_file"
            return 1
        else
            echo "Warning: No explicit status marker found in output"
            # Still try to extract any files that were created
            return 0
        fi
    fi
    
    return 0
}

# Create expect script for interactive automation
create_expect_script() {
    local prompt_file="$1"
    local model="$2"
    local max_turns="$3"
    local output_file="$4"
    
    cat > "$working_dir/.claude_expect.exp" <<'EXPECT_SCRIPT'
#!/usr/bin/expect -f

set timeout -1
set prompt_file [lindex $argv 0]
set model [lindex $argv 1]
set max_turns [lindex $argv 2]
set output_file [lindex $argv 3]

# Read prompt content
set fp [open $prompt_file r]
set prompt_content [read $fp]
close $fp

# Start Claude
spawn claude --model $model --max-turns $max_turns

# Wait for Claude to be ready
expect {
    ">" { send "$prompt_content\r" }
    "Claude>" { send "$prompt_content\r" }
    timeout { exit 1 }
}

# Capture output
log_file $output_file

# Wait for completion
expect {
    "<<<STATUS: COMPLETE" { 
        expect ">>>END_STATUS"
        send "\x04"  ; # Ctrl-D to exit
    }
    "<<<STATUS: ERROR" {
        expect ">>>END_STATUS"
        send "\x04"
    }
    timeout { 
        send "\x04"
    }
}

expect eof
EXPECT_SCRIPT
    
    chmod +x "$working_dir/.claude_expect.exp"
}

# Parse Claude's output and extract files
parse_claude_output() {
    local output_file="$1"
    local target_dir="$2"
    
    # Ensure artifacts directory exists
    mkdir -p "$target_dir/artifacts"
    
    # Extract files using our markers
    local in_file=false
    local current_file=""
    local file_content=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^"<<<CREATE_FILE: "(.+)$ ]]; then
            current_file="${BASH_REMATCH[1]}"
            in_file=true
            file_content=""
        elif [[ "$line" == ">>>END_FILE" ]] && [[ "$in_file" == true ]]; then
            # Save the file
            echo -n "$file_content" > "$target_dir/artifacts/$current_file"
            echo "✓ Created: artifacts/$current_file"
            in_file=false
            current_file=""
        elif [[ "$in_file" == true ]]; then
            if [[ -n "$file_content" ]]; then
                file_content+=$'\n'
            fi
            file_content+="$line"
        fi
    done < "$output_file"
}

# Extract status information
extract_status() {
    local output_file="$1"
    
    awk '
    /<<<STATUS: / { 
        status = 1
        print substr($0, index($0, "STATUS: ") + 8)
        next
    }
    />>>END_STATUS/ { 
        status = 0
    }
    status && /^- / { 
        print $0
    }
    ' "$output_file"
}

# Fallback interactive mode with instructions
launch_interactive_with_instructions() {
    local prompt_file="$1"
    local working_dir="$2"
    local model="$3"
    
    echo ""
    echo "=== LAUNCHING INTERACTIVE MODE ==="
    echo "Since automated execution isn't working, launching Claude interactively."
    echo ""
    echo "IMPORTANT: When Claude opens, please:"
    echo "1. Paste or type the following prompt"
    echo "2. Let Claude complete the task"
    echo "3. Exit when done (Ctrl+D or type 'exit')"
    echo ""
    echo "Press Enter to see the prompt, then press Enter again to launch Claude..."
    read -r
    
    echo "=== PROMPT TO PASTE ==="
    cat "$prompt_file"
    echo "=== END PROMPT ==="
    echo ""
    echo "Press Enter to launch Claude..."
    read -r
    
    cd "$working_dir"
    if command -v claude &> /dev/null; then
        claude --model "$model"
    else
        npx claude-code --model "$model"
    fi
}

# Monitor mode - watch for file creation
monitor_artifacts() {
    local watch_dir="$1"
    local expected_file="$2"
    local timeout="${3:-300}"  # 5 minutes default
    
    echo "Monitoring for $expected_file creation..."
    
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if [[ -f "$watch_dir/$expected_file" ]]; then
            echo "✓ Detected: $expected_file"
            return 0
        fi
        sleep 2
        ((elapsed += 2))
        printf "."
    done
    
    echo ""
    echo "✗ Timeout waiting for $expected_file"
    return 1
}

export -f create_structured_prompt
export -f execute_claude_session
export -f parse_claude_output
export -f extract_status
export -f launch_interactive_with_instructions
export -f monitor_artifacts