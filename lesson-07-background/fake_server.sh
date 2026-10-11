#!/bin/bash
# Simulates a server logging activity over time, including one deliberate error.
LOG=/Users/viplavsingh/Desktop/project/claude_code/lesson-07-background/server.log
: > "$LOG"
for i in 1 2 3; do
  sleep 2
  echo "[$(date +%T)] INFO request handled ok (req #$i)" >> "$LOG"
done
sleep 2
echo "[$(date +%T)] ERROR database connection timed out" >> "$LOG"
sleep 2
echo "[$(date +%T)] INFO recovered, back to normal" >> "$LOG"
