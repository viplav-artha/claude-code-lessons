---
name: bugfix-log
description: Use this skill whenever the user asks to log, document, or record a bug fix. Appends a consistently formatted entry to FIXES.md with Root Cause, Fix, and Verification sections.
---

When invoked, append a new entry to `FIXES.md` in the project root (create the
file with a top-level `# Fix Log` heading if it doesn't exist yet). Each entry
uses exactly this template, filled in from the fix being described:

```
## <short title> — <YYYY-MM-DD>

**Root Cause:** <one or two sentences on why the bug existed>

**Fix:** <what changed, file:line references where useful>

**Verification:** <how it was confirmed to work>
```

Keep each section tight — no filler. If any detail isn't known, write
"unknown" rather than guessing.
