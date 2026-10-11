#!/bin/bash
# Custom statusline: shows model, session cost so far, and git status —
# a live callback to the fact this lessons project still isn't a git repo.

input=$(cat)
MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // empty')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST_FMT=$(printf "%.3f" "$COST")

if git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
  [ -z "$BRANCH" ] && BRANCH="detached"
  GIT_STATUS="git:$BRANCH"
else
  GIT_STATUS="no git repo"
fi

echo "[$MODEL] \$${COST_FMT} this session | $GIT_STATUS"
