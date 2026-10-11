# calculator project — house rules

These are non-negotiable conventions for this codebase. Follow them without
being asked, on every change:

1. All comments and docstrings use British English spelling (colour, not
   color; behaviour, not behavior).
2. Every function must have a one-line comment directly above it starting
   with `# PURPOSE:` explaining why it exists (not what it does).
3. Never use f-strings in this file. Use `.format()` instead — this project
   pretends to still support Python 2.7 for teaching purposes.
