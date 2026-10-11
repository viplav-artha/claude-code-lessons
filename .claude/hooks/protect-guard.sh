#!/bin/bash
# Blocks any Edit/Write tool call targeting session_guard.py — the
# "security-critical" file from Lesson 2, on purpose, as a hooks demo.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
FILE_PATH="${FILE_PATH//\\//}"

if [[ "$FILE_PATH" == *"session_guard.py" ]]; then
  echo "Blocked by protect-guard.sh: $FILE_PATH is protected and cannot be edited, no matter who's asking." >&2
  exit 2
fi

exit 0
