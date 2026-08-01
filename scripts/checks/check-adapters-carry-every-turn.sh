#!/bin/sh
# The every-turn communication rules bind EVERY reader-facing sentence, so an agent that
# never loads them is an agent they do not govern. AGENTS.md is their source of truth; the
# Cursor and Copilot adapters inline a condensed index precisely because those tools don't
# reliably follow a bare pointer (README, "Repo layout"), so each must carry every rule by
# name or the rules reach nobody using them.
#
# The Claude and Gemini adapters are intentionally excluded: both are thin pointers whose
# first instruction is to read AGENTS.md, where the full section already lives.
#
# Vacuity is the failure mode this guards against — a check that silently verifies nothing
# reads exactly like a passing one. So: no AGENTS.md, or an AGENTS.md with no such section,
# is "nothing to mirror" and passes; a section that parses to ZERO rules is a FAIL, because
# that means the format drifted and every adapter would pass against an empty set.
# Portable POSIX sh; zero runtime deps beyond awk/sed/grep.
set -u

src="AGENTS.md"
[ -f "$src" ] || { echo "ok: no $src — nothing to mirror"; exit 0; }

grep -q '^## Every-turn rules' "$src" || {
  echo "ok: $src carries no every-turn section — nothing to mirror"
  exit 0
}

# The rules are the bolded lead-ins of the bullets under that heading, verbatim.
rules=$(awk '/^## Every-turn rules/{f=1;next} f&&/^## /{exit} f' "$src" \
  | sed -n 's/^- \*\*\([^*]*\)\*\*.*/\1/p')

[ -n "$rules" ] || {
  echo "FAIL: the every-turn section exists in $src but parses to zero rules."
  echo "  Expected bullets shaped '- **Rule lead.** …'. Fix the section or this check"
  echo "  passes every adapter against an empty set."
  exit 1
}

adapters="adapters/cursor/methodology.mdc adapters/copilot/copilot-instructions.md"
status=0

for a in $adapters; do
  if [ ! -f "$a" ]; then
    echo "FAIL: enumerating adapter missing: $a"
    status=1
    continue
  fi
  # Collected in a subshell, so test the captured output rather than a lost $status.
  missing=$(printf '%s\n' "$rules" | while IFS= read -r r; do
    [ -n "$r" ] || continue
    grep -qF "$r" "$a" || printf '  %s\n' "$r"
  done)
  if [ -n "$missing" ]; then
    echo "FAIL: $a is missing every-turn rule(s) that $src states:"
    printf '%s\n' "$missing"
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "ok: every enumerating adapter carries all $(printf '%s\n' "$rules" | grep -c .) every-turn rules"
fi

exit "$status"
