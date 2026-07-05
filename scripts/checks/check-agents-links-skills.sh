#!/bin/sh
# AGENTS.md must link every skill (skills/<slug>/SKILL.md) and link no skill that
# does not exist on disk. Two-way set equality between skills/ dirs and AGENTS.md links.
# Portable POSIX sh; uses temp files + comm (no <() process substitution).
set -u
[ -f AGENTS.md ] || { echo "FAIL: AGENTS.md not found (run from repo root)"; exit 2; }
[ -d skills ] || { echo "FAIL: skills/ not found (run from repo root)"; exit 2; }
dirs=$(mktemp) || exit 2
links=$(mktemp) || exit 2
trap 'rm -f "$dirs" "$links"' EXIT INT TERM
ls -d skills/*/ 2>/dev/null | sed 's#^skills/##; s#/$##' | sort -u > "$dirs"
[ -s "$dirs" ] || { echo "FAIL: no skills found under skills/"; exit 2; }
grep -oE 'skills/[a-z0-9-]+/SKILL\.md' AGENTS.md \
  | sed -E 's#skills/([a-z0-9-]+)/SKILL\.md#\1#' | sort -u > "$links"
status=0
miss=$(comm -23 "$dirs" "$links")
extra=$(comm -13 "$dirs" "$links")
if [ -n "$miss" ]; then
  echo "FAIL: AGENTS.md does not link these skills:"; printf '  %s\n' $miss; status=1
fi
if [ -n "$extra" ]; then
  echo "FAIL: AGENTS.md links non-existent skills:"; printf '  %s\n' $extra; status=1
fi
if [ "$status" -eq 0 ]; then
  echo "ok: AGENTS.md links all $(wc -l < "$dirs" | tr -d ' ') skills"
fi
exit "$status"
