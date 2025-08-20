#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Go up one level to get .claude directory
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
# Log file path
LOG_FILE="$CLAUDE_DIR/command.log"

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Read the JSON input from stdin
INPUT=$(cat)

# Always write something to confirm hook is running
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hook called" >> "$LOG_FILE"

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