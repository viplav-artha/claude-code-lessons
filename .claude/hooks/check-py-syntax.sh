#!/bin/bash
# Stop hook demo — before letting Claude end its turn, verify every .py file
# in the project actually compiles. If any are broken, force Claude to keep
# working instead of declaring victory.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd')

BROKEN_FILES=()
while IFS= read -r pyfile; do
  if ! python3 -m py_compile "$pyfile" 2>/dev/null; then
    BROKEN_FILES+=("$pyfile")
  fi
done < <(find "$CWD" -name "*.py" -type f -not -path "*/.git/*")

if [ ${#BROKEN_FILES[@]} -gt 0 ]; then
  FILES_LIST=$(printf '%s\n' "${BROKEN_FILES[@]}" | sed "s|^${CWD}/||" | tr '\n' ',' | sed 's/,$//')
  echo "Cannot stop: syntax errors remain in: $FILES_LIST" >&2
  exit 2
fi

exit 0
