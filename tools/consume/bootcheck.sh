#!/bin/sh
# bootcheck.sh — tier-independent methodology integrity check.
#
# Usage: bootcheck.sh <skills-root> <tier>
#   Reads ONLY the consumer's tier symlink (<skills-root>/<tier>) and the frozen
#   .skillset inside its target. Asserts the tier resolves and is complete:
#     - symlink absent / dangling                    -> MISSING
#     - .skillset absent or != actual skills/*/ dirs -> PARTIAL
#   On a fault it exits non-zero and writes ONE stderr line ending in the token,
#   matching  ^METHODOLOGY .* (MISSING|PARTIAL)$  (token LAST). No external record,
#   no CORRUPTED — read-only + produce-time fidelity already cover content.
#
# This must be installed OUTSIDE any tier (by provisioning) so a dangling tier
# cannot disable it. It supersedes the P9 prototype (which was token-FIRST and
# used a .pinned-sha / DRIFTED shape). POSIX sh.
set -eu

# fail <message> <TOKEN>  — token LAST, on stderr, then exit non-zero.
fail() { printf 'METHODOLOGY %s %s\n' "$1" "$2" >&2; exit 1; }

[ $# -ge 2 ] || { printf 'usage: bootcheck.sh <skills-root> <tier>\n' >&2; exit 2; }
root=$1
tier=$2
dir="$root/$tier"

[ -e "$dir" ] || fail "tier '$tier' does not resolve" MISSING

want="$dir/.skillset"
[ -f "$want" ] || fail "tier '$tier' has no .skillset" PARTIAL

have=$(mktemp)
trap 'rm -f "$have"' EXIT
set -- "$dir"/skills/*/
if [ -d "$1" ]; then
  for s in "$@"; do basename "$s"; done | LC_ALL=C sort >"$have"
else
  : >"$have"
fi
cmp -s "$want" "$have" || fail "tier '$tier' skill set does not match .skillset" PARTIAL

printf 'METHODOLOGY OK — tier %s, %s skill(s)\n' "$tier" "$(wc -l <"$want" | tr -d ' ')"
