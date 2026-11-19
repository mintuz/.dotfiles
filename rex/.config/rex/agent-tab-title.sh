#!/bin/sh
# Copies the terminal title of an agent's pane to the Rex tab that holds the
# pane. Claude Code, Codex and omp set the title to a short summary of the
# session. install.sh adds this script to the Stop hooks of Claude Code and
# Codex, and an omp extension runs it when an omp run ends.
# Outside Rex, or when the pane has no title, the script does nothing. It
# always exits 0, so a failure never stops the agent.

[ -n "${REX_SESSION:-}" ] && [ -n "${REX_BLOCK:-}" ] || exit 0

# Remove omp's "π > " prefix, whose separator shows the run state, and leading
# spinner, status or emoji characters, such as "✳ ".
title=$(rex api call -s "$REX_SESSION" com.superlogical.terminal.title "{\"block_id\":\"$REX_BLOCK\"}" 2>/dev/null |
  jq -r '.title // empty' | sed -e 's/^π [^ ]* //' -e 's/^[^[:alnum:]]*//')
[ -n "$title" ] || exit 0

window=$(rex block inspect -s "$REX_SESSION" "$REX_BLOCK" --json 2>/dev/null | jq -r '.block.window_id // empty')
[ -n "$window" ] || exit 0

rex window rename -s "$REX_SESSION" "$window" "$title" >/dev/null 2>&1
exit 0
