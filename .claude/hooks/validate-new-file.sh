#!/bin/bash

# Read the JSON input from stdin
INPUT=$(cat)

# Extract file path from the JSON input
FILE_PATH=$(echo "$INPUT" | jq -r '.args.file_path // .args.path // empty')

# Exit if no file path found
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Check for .env files (forbidden)
if [[ "$FILE_PATH" =~ \.env(\.|$) ]]; then
  echo "ERROR: .env files are not allowed. Use the 'config' module instead."
  echo "See: https://www.npmjs.com/package/config"
  exit 1
fi

# Check for TypeScript files (forbidden)
if [[ "$FILE_PATH" =~ \.(ts|tsx)$ ]] && [[ ! "$FILE_PATH" =~ \.d\.ts$ ]]; then
  echo "ERROR: TypeScript files are not allowed. This project uses JavaScript only."
  exit 1
fi

# Check for CommonJS syntax in JS files
if [[ "$FILE_PATH" =~ \.js$ ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.args.content // empty')
  if [[ -n "$CONTENT" ]]; then
    # Check for CommonJS patterns
    if echo "$CONTENT" | grep -qE "(^|[^a-zA-Z])require\s*\(|module\.exports|exports\.[a-zA-Z]"; then
      echo "ERROR: CommonJS syntax detected. This project uses ESM (ES Modules) only."
      echo "Use 'import' and 'export' instead of 'require' and 'module.exports'"
      exit 1
    fi
  fi
fi

# Check for unauthorized migration files
if [[ "$FILE_PATH" =~ prisma/migrations/ ]]; then
  echo "ERROR: Prisma migrations are not allowed. Use schema.sql for database schema management."
  exit 1
fi

exit 0