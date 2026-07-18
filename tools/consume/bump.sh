#!/bin/sh
# bump.sh — install a new pinned commit as the current methodology.
#
# Usage: bump.sh <checkout> <ref> <intended-sha> <mat-root> <symlink> [remote]
#   Resolves <ref> ONCE, requires it to equal <intended-sha>, has the operator
#   review any change to executable content (session hooks) before it lands,
#   materializes the pin (via materialize.sh), atomically re-points <symlink> at
#   it, and reaps old materializations keeping the current AND the previous one
#   (for rollback). Refuses --force. A `git fetch` (only if <remote> is given) is
#   best-effort and its exit status is NOT trusted — the SHA compare is the gate.
#
# Non-interactive: BUMP_ASSUME_YES=1 auto-approves the executable-content review
# (for automated first-setup / an already-reviewed pin). POSIX sh.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
die() { printf 'bump: FAIL — %s\n' "$1" >&2; exit 1; }

# --force is forbidden anywhere in argv (a bump must never clobber).
for a in "$@"; do [ "$a" = "--force" ] && die "--force is forbidden"; done

[ $# -ge 5 ] || die "usage: bump.sh <checkout> <ref> <intended-sha> <mat-root> <symlink> [remote]"
checkout=$1; ref=$2; intended=$3; matroot=$4; symlink=$5; remote=${6:-}

# Executable content that a bump could newly run in a consumer session:
EXEC_PATHS="claude-tier/hooks claude-tier/scripts"

[ -d "$checkout/.git" ] || die "not a git checkout: $checkout"
[ -d "$matroot" ] || mkdir -p "$matroot" || die "cannot create mat-root: $matroot"

# Best-effort, UNtrusted fetch — a clobbered/rejected tag can leave `git fetch`
# exiting 0, so we never gate on it; the SHA compare below is the real gate.
if [ -n "$remote" ]; then git -C "$checkout" fetch --tags "$remote" >/dev/null 2>&1 || true; fi

# Resolve ONCE. The same $got is used for the diff, the materialize, and the pin
# (no re-resolution — closes the review-vs-ship TOCTOU).
got=$(git -C "$checkout" rev-parse --verify --quiet "${ref}^{commit}") || die "cannot resolve ref: $ref"
[ "$got" = "$intended" ] || die "resolved SHA $got != intended $intended (moved tag / lying fetch?)"

# The previous pin: the SHA the symlink currently points at (dir basename).
old_sha=""
[ -L "$symlink" ] && old_sha=$(basename "$(readlink "$symlink")")
empty_tree=$(git -C "$checkout" hash-object -t tree /dev/null)
base=${old_sha:-$empty_tree}

# Operator reviews any executable-content change before it lands.
# shellcheck disable=SC2086  # EXEC_PATHS is a deliberate multi-path list for git diff
execdiff=$(git -C "$checkout" diff "$base" "$got" -- $EXEC_PATHS 2>/dev/null || true)
if [ -n "$execdiff" ] && [ "${BUMP_ASSUME_YES:-}" != 1 ]; then
  printf '%s\n' "$execdiff"
  printf 'bump: the above executable-content change ships with %s. Apply? [y/N] ' "$got" >&2
  read -r ans || ans=""
  case "$ans" in y | Y | yes | YES) ;; *) die "operator declined the executable-content change" ;; esac
fi

# Materialize the SAME resolved SHA (idempotent — reuse an existing one).
target="$matroot/$got"
[ -e "$target" ] || sh "$here/materialize.sh" "$checkout" "$got" "$target" >/dev/null || die "materialize failed"

# Atomically (re-)point the consumer symlink (portable; `mv -T` is GNU-only).
ln -sfn "$target" "$symlink" || die "symlink publish failed"

# Reap: keep current ($got) and previous ($old_sha); remove strictly-older
# materializations and stale temp dirs — NEVER the current or previous.
for d in "$matroot"/* "$matroot"/.mat.tmp.*; do
  [ -e "$d" ] || continue
  b=$(basename "$d")
  [ "$b" = "$got" ] && continue
  [ -n "$old_sha" ] && [ "$b" = "$old_sha" ] && continue
  chmod -R u+w "$d" 2>/dev/null || true
  rm -rf "$d"
done

printf 'bump: OK — %s -> %s @ %s (previous kept: %s)\n' "$symlink" "$target" "$got" "${old_sha:-none}"
