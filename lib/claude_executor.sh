#!/usr/bin/env bash

# Claude Executor Library
# Handles execution and parsing of Claude Code instances

set -euo pipefail

# Source this script to use its functions
CLAUDE_EXECUTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute Claude and extract artifacts
execute_claude_with_artifacts() {
    local prompt_file="$1"
    local working_dir="$2"
    local model="${3:-opus}"
    local max_turns="${4:-10}"
    local expected_artifacts="${5:-}"  # comma-separated list
    
    # Create a wrapper prompt that ensures structured output
    local wrapped_prompt_file="${working_dir}/wrapped_prompt.txt"
    cat > "$wrapped_prompt_file" <<EOF
$(cat "$prompt_file")

IMPORTANT OUTPUT INSTRUCTIONS:
When you create any files or artifacts, please clearly mark them with delimiters so they can be extracted:

For each file you create, use this format:
===FILE_START: filename.md===
[file content here]
===FILE_END: filename.md===

At the end of your response, provide a summary:
===SUMMARY_START===
- What was accomplished
- Files created
- Any issues encountered
===SUMMARY_END===
EOF
    
    # Execute Claude
    local output_file="${working_dir}/claude_output_$(date +%s).txt"
    cd "$working_dir"
    
    # Determine Claude command
    local claude_cmd
    if command -v claude &> /dev/null; then
        claude_cmd="claude"
    else
        claude_cmd="npx claude-code"
    fi
    
    # Run Claude and capture output
    echo "Executing Claude with model $model..."
    local prompt_content=$(cat "$wrapped_prompt_file")
    
    if $claude_cmd --model "$model" --max-turns "$max_turns" -p "$prompt_content" > "$output_file" 2>&1; then
        # Extract artifacts from output
        extract_artifacts_from_output "$output_file" "$working_dir"
        
        # Extract and display summary
        extract_summary "$output_file"
        
        # Check if expected artifacts were created
        if [[ -n "$expected_artifacts" ]]; then
            check_expected_artifacts "$working_dir" "$expected_artifacts"
        fi
        
        return 0
    else
        echo "Claude execution failed. Output:"
        cat "$output_file"
        return 1
    fi
}

# Extract files from Claude's output
extract_artifacts_from_output() {
    local output_file="$1"
    local target_dir="$2"
    
    # Ensure artifacts directory exists
    mkdir -p "$target_dir/artifacts"
    
    # Extract files using awk - BSD compatible
    awk -v target_dir="$target_dir" '
    BEGIN {
        collecting = 0
        filepath = ""
    }
    /===FILE_START: .+===/ {
        gsub(/===FILE_START: /, "", $0)
        gsub(/===/, "", $0)
        filename = $0
        filepath = target_dir "/artifacts/" filename
        collecting = 1
        next
    }
    /===FILE_END: .+===/ {
        collecting = 0
        if (filepath != "") {
            close(filepath)
            print "Extracted: " filepath
        }
        next
    }
    collecting == 1 && filepath != "" {
        print >> filepath
    }
    ' "$output_file"
}

# Extract summary from output
extract_summary() {
    local output_file="$1"
    
    awk '
    /===SUMMARY_START===/ { collecting = 1; next }
    /===SUMMARY_END===/ { collecting = 0; next }
    collecting { print }
    ' "$output_file"
}

# Check if expected artifacts exist
check_expected_artifacts() {
    local target_dir="$1"
    local expected="$2"
    
    IFS=',' read -ra artifacts <<< "$expected"
    local all_found=true
    
    for artifact in "${artifacts[@]}"; do
        artifact=$(echo "$artifact" | xargs)  # trim whitespace
        if [[ -f "$target_dir/artifacts/$artifact" ]]; then
            echo "✓ Found expected artifact: $artifact"
        else
            echo "✗ Missing expected artifact: $artifact"
            all_found=false
        fi
    done
    
    if [[ "$all_found" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Execute a single-turn task with Sonnet
execute_sonnet_task() {
    local task_description="$1"
    local context_file="$2"
    local working_dir="$3"
    local task_id="$4"
    
    # Create task prompt
    local task_prompt_file="$working_dir/prompts/task_${task_id}.txt"
    cat > "$task_prompt_file" <<EOF
You are implementing a specific development task as part of a larger refactor.

TASK: $task_description

CONTEXT:
$(cat "$context_file")

Please ULTRATHINK through this task and implement it completely. Focus on:
1. Understanding the requirements fully
2. Planning the implementation approach
3. Writing clean, well-tested code
4. Documenting your changes

Create any necessary files using the format:
===FILE_START: filename===
[content]
===FILE_END: filename===
EOF
    
    # Execute with Sonnet
    execute_claude_with_artifacts \
        "$task_prompt_file" \
        "$working_dir" \
        "sonnet-3.5" \
        "5" \
        ""
}

# Parse task list and execute each task
execute_task_list() {
    local tasks_file="$1"
    local working_dir="$2"
    local phase_num="$3"
    
    # Extract tasks from markdown file
    local task_num=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^###[[:space:]]Task[[:space:]].*:(.*)$ ]]; then
            ((task_num++))
            local task_desc="${BASH_REMATCH[1]}"
            echo "Executing Task $task_num: $task_desc"
            
            execute_sonnet_task \
                "$task_desc" \
                "$tasks_file" \
                "$working_dir" \
                "${phase_num}_${task_num}"
        fi
    done < "$tasks_file"
}

# Export functions for use in main script
export -f execute_claude_with_artifacts
export -f extract_artifacts_from_output
export -f extract_summary
export -f check_expected_artifacts
export -f execute_sonnet_task
export -f execute_task_list