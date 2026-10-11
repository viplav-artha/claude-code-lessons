#!/bin/bash
# PostToolUse demo hook — runs AFTER every Edit/Write, checks Python syntax.
# Can't undo the edit (too late), but can surface a problem back to Claude.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
  exit 0
fi

ERROR=$(python3 -m py_compile "$FILE_PATH" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "Syntax error in $FILE_PATH after edit:\n$ERROR" >&2
  exit 2
fi

exit 0
