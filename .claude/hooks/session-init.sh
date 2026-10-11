#!/bin/bash
# SessionStart hook — injects a short project briefing as context the
# instant a session starts, resumes, or is cleared. Claude sees this
# stdout automatically, without you having to ask "remind me what's here."

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd')
REASON=$(echo "$INPUT" | jq -r '.session_start_reason')

echo "=== claude_code lessons project — session briefing ==="
echo "Trigger: $REASON"
echo ""
echo "Lesson folders present:"
find "$CWD" -maxdepth 1 -type d -name "lesson-*" -exec basename {} \;
echo ""
echo "Hooks currently configured in .claude/settings.json:"
jq -r '.hooks | keys[]' "$CWD/.claude/settings.json" 2>/dev/null
echo ""
echo "Custom subagents available:"
find "$CWD/.claude/agents" -maxdepth 1 -name "*.md" -exec basename {} .md \; 2>/dev/null
echo ""
echo "Custom skills available:"
find "$CWD/.claude/skills" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null

exit 0
