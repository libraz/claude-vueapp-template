#!/bin/bash

# Read the JSON input from stdin
INPUT=$(cat)

# Extract file path from the JSON input
FILE_PATH=$(echo "$INPUT" | jq -r '.args.file_path // .args.path // empty')

# Exit if no file path found
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Extract filename without path
FILENAME=$(basename "$FILE_PATH")

# Skip hidden files and special files
if [[ "$FILENAME" =~ ^\. ]] || [[ "$FILENAME" =~ ^(package\.json|tsconfig\.json|README\.md|CLAUDE\.md|LICENSE)$ ]]; then
  exit 0
fi

# Check for Vue components (should be PascalCase)
if [[ "$FILE_PATH" =~ src/components/.*\.vue$ ]]; then
  if ! [[ "$FILENAME" =~ ^[A-Z][a-zA-Z0-9]*\.vue$ ]]; then
    echo "ERROR: Vue component files must use PascalCase naming (e.g., MyComponent.vue)"
    echo "File: $FILE_PATH"
    exit 1
  fi
  exit 0
fi

# Check for test files (should end with .test.js)
if [[ "$FILE_PATH" =~ tests/.*\.js$ ]] && [[ ! "$FILENAME" =~ \.test\.js$ ]]; then
  echo "WARNING: Test files should end with .test.js"
  echo "File: $FILE_PATH"
fi

# Check general files (should be kebab-case)
BASE_NAME="${FILENAME%.*}"
if [[ "$BASE_NAME" =~ [A-Z] ]] || [[ "$BASE_NAME" =~ _ ]]; then
  # Skip if it's a known exception
  if [[ ! "$FILE_PATH" =~ (\.vue$|\.md$|Dockerfile|\.yml$|\.yaml$) ]]; then
    echo "ERROR: File names must use kebab-case (lowercase with hyphens)"
    echo "File: $FILE_PATH"
    echo "Expected format: lowercase-with-hyphens.ext"
    exit 1
  fi
fi

exit 0