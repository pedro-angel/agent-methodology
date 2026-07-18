#!/bin/sh
# materialize.sh — produce a read-only, fidelity-verified export of a commit.
#
# Usage: materialize.sh <checkout> <sha> <out-dir>
#   <checkout>  a git checkout of the pack (the source of the export)
#   <sha>       the commit to materialize (the pin of record)
#   <out-dir>   a NOT-yet-existing directory to create as the materialization
#
# On success <out-dir> holds the export of <sha> (no .git), a frozen .skillset
# descriptor derived from its own skills/, and is read-only (a-w). The build is
# all-or-nothing: any failure leaves no partial <out-dir> and exits non-zero
# with a message on stderr. Idempotence is the caller's job (it refuses to
# overwrite an existing <out-dir>). POSIX sh, zero runtime deps beyond git+tar.
set -eu

die() { printf 'materialize: FAIL — %s\n' "$1" >&2; exit 1; }

[ $# -eq 3 ] || die "usage: materialize.sh <checkout> <sha> <out-dir>"
checkout=$1
sha=$2
out=$3

[ -d "$checkout/.git" ] || die "not a git checkout: $checkout"
git -C "$checkout" rev-parse --verify --quiet "${sha}^{commit}" >/dev/null 2>&1 \
  || die "not a commit in $checkout: $sha"
[ -e "$out" ] && die "out-dir already exists (reap or choose a fresh path): $out"
parent=$(dirname "$out")
[ -d "$parent" ] || die "parent dir does not exist: $parent"

tmp=$(mktemp -d "$parent/.mat.tmp.XXXXXX") || die "mktemp failed"
tar="$tmp.tar"
fail="$tmp.fail"
cleanup() { chmod -R u+w "$tmp" 2>/dev/null || true; rm -rf "$tmp" "$tar" "$fail"; }
trap cleanup EXIT INT TERM HUP

# Archive then extract as TWO checked steps — POSIX sh has no `pipefail`, so a
# piped `git archive | tar` would hide a mid-stream failure.
git -C "$checkout" archive --format=tar "$sha" >"$tar" || die "git archive failed"
tar -x -f "$tar" -C "$tmp" || die "tar extract failed (truncated / disk-full?)"

# Produce-time fidelity: every blob in the commit's tree must hash-match the
# extracted file. Catches a truncated or corrupt extraction that MISSING/PARTIAL
# (which only compare dir names) never would. Recorded to a file because the
# `while` runs in a pipe subshell.
: >"$fail"
git -C "$checkout" ls-tree -r "$sha" | while IFS="$(printf '\t')" read -r meta path; do
  blob=$(printf '%s\n' "$meta" | awk '{print $3}')
  got=$(git -C "$checkout" hash-object "$tmp/$path" 2>/dev/null || printf 'MISSING')
  [ "$got" = "$blob" ] || printf '%s\n' "$path" >>"$fail"
done
if [ -s "$fail" ]; then die "export fidelity failed for: $(tr '\n' ' ' <"$fail")"; fi

# Freeze the skill-set descriptor from the export's OWN skills/ dirs (never a
# hand-authored list — that would re-introduce a silent drift surface).
# (positional params $1..$3 are already saved in named vars, so `set --` is free)
set -- "$tmp"/skills/*/
if [ -d "$1" ]; then
  for d in "$@"; do basename "$d"; done | LC_ALL=C sort >"$tmp/.skillset"
else
  : >"$tmp/.skillset"   # a skill-less tier (glob stayed literal) → empty descriptor
fi

chmod -R a-w "$tmp"

# Publish atomically within the same filesystem (rename the fully-built temp).
mv "$tmp" "$out" || die "publish (mv) failed"
trap - EXIT INT TERM HUP
rm -f "$tar" "$fail"
printf 'materialize: OK — %s @ %s (%s skills)\n' "$out" "$sha" "$(wc -l <"$out/.skillset" | tr -d ' ')"
