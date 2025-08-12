#!/bin/bash

# Log file path
LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/command.log"

# Read the JSON input from stdin
INPUT=$(cat)

# Extract tool name and timestamp
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool // "unknown"')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Extract command based on tool type
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.args.command // "N/A"')
  DESCRIPTION=$(echo "$INPUT" | jq -r '.args.description // ""')
  
  # Log the command
  echo "[$TIMESTAMP] Bash: $COMMAND" >> "$LOG_FILE"
  if [ -n "$DESCRIPTION" ] && [ "$DESCRIPTION" != "null" ]; then
    echo "  Description: $DESCRIPTION" >> "$LOG_FILE"
  fi
fi

# Always pass through (don't block execution)
exit 0