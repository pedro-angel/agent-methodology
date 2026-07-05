#!/bin/sh
# Every enumerating adapter must name ALL skills, so a condensed index (the Cursor,
# Copilot, and Gemini adapters inline one) cannot silently drift from skills/.
# The Claude adapter is intentionally excluded: it delegates to AGENTS.md + native
# skill auto-discovery and enumerates nothing.
# Portable POSIX sh; zero runtime deps.
set -u
[ -d skills ] || { echo "FAIL: skills/ not found (run from repo root)"; exit 2; }
skills=$(ls -d skills/*/ 2>/dev/null | sed 's#^skills/##; s#/$##' | sort -u)
[ -n "$skills" ] || { echo "FAIL: no skills found under skills/"; exit 2; }
adapters="adapters/cursor/methodology.mdc adapters/copilot/copilot-instructions.md adapters/gemini/GEMINI.md"
status=0
for a in $adapters; do
  [ -f "$a" ] || { echo "FAIL: enumerating adapter missing: $a"; status=1; continue; }
  for s in $skills; do
    grep -qF "$s" "$a" || { echo "FAIL: $a does not list skill '$s'"; status=1; }
  done
done
if [ "$status" -eq 0 ]; then
  echo "ok: every enumerating adapter lists all $(printf '%s\n' $skills | grep -c .) skills"
fi
exit "$status"
