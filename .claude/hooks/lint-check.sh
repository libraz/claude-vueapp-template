#!/bin/bash

# Read the JSON input from stdin
INPUT=$(cat)

# Extract file path from the JSON input
FILE_PATH=$(echo "$INPUT" | jq -r '.args.file_path // .args.path // empty')

# Exit if no file path found
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Only process JavaScript/Vue/Markdown files
if [[ ! "$EXT" =~ ^(js|vue|md)$ ]]; then
  exit 0
fi

# Run ESLint if available
if command -v eslint &> /dev/null && [ -f ".eslintrc.js" -o -f ".eslintrc.json" ]; then
  echo "Running ESLint on $FILE_PATH..."
  eslint "$FILE_PATH" --fix
fi

# Run Prettier if available
if command -v prettier &> /dev/null && [ -f ".prettierrc" -o -f ".prettierrc.json" ]; then
  echo "Running Prettier on $FILE_PATH..."
  prettier --write "$FILE_PATH"
fi

# Check for Vue Options API usage
if [[ "$EXT" == "vue" ]]; then
  CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")
  if echo "$CONTENT" | grep -qE "export\s+default\s*{[^}]*(data|methods|computed|watch|created|mounted)\s*\(|:"; then
    echo "WARNING: Vue Options API detected. Please use Composition API with <script setup>"
  fi
fi

# Run markdownlint for Markdown files
if [[ "$EXT" == "md" ]]; then
  if command -v markdownlint &> /dev/null; then
    echo "Running markdownlint on $FILE_PATH..."
    markdownlint "$FILE_PATH" --fix 2>&1 || echo "WARNING: Markdown linting issues detected"
  elif command -v npx &> /dev/null; then
    echo "Running markdownlint on $FILE_PATH..."
    npx markdownlint-cli "$FILE_PATH" --fix 2>&1 || echo "WARNING: Markdown linting issues detected"
  fi
fi

# Validate OpenAPI spec if modified
if [[ "$FILE_PATH" =~ openapi/.*\.(yml|yaml)$ ]]; then
  if command -v yarn &> /dev/null && [ -f "package.json" ]; then
    echo "Validating OpenAPI specification..."
    yarn validate:openapi 2>/dev/null || echo "WARNING: OpenAPI validation failed or script not found"
  fi
fi

exit 0