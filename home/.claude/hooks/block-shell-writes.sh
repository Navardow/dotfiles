#!/usr/bin/env bash
# PreToolUse hook: make Claude ask for approval before Bash commands that write
# files or hide other commands. Only affects Claude's tool calls, not your own shell.
# Skipped in auto mode; git commit/stage stay blocked by the deny rules in settings.json.
input=$(cat)
[[ $(jq -r '.permission_mode // ""' <<<"$input") == auto ]] && exit 0
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")

# Drop redirects that don't touch real files (/dev/null, 2>&1, scratchpad) and arrows like -> =>
scrubbed=$(printf '%s' "$cmd" | sed -E \
  -e 's#[0-9&]?>>?[[:space:]]*/dev/(null|stdout|stderr)##g' \
  -e 's#[0-9]*>&[0-9-]+##g' \
  -e 's#[0-9&]?>>?[[:space:]]*/tmp/claude-[^[:space:]]*##g' \
  -e 's#[-=]>##g')

reason=""
if grep -q '>' <<<"$scrubbed"; then
  reason="output redirection to a file"
elif grep -qE '\b(sed|perl)\b[^|;&]*[[:space:]](-[a-zA-Z]*i|--in-place)' <<<"$cmd"; then
  reason="in-place edit (sed/perl -i)"
elif grep -qE '(^|[|;&[:space:]])tee\b' <<<"$cmd"; then
  reason="tee"
elif grep -qE '\bdd\b.*\bof=' <<<"$cmd"; then
  reason="dd of="
elif grep -qE '(^|[|;&[:space:]])truncate\b' <<<"$cmd"; then
  reason="truncate"
elif grep -qE '\$\(|`' <<<"$cmd"; then
  reason="command substitution"
fi

if [[ -n $reason ]]; then
  jq -n --arg r "Shell command needs approval ($reason)." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
fi
exit 0
