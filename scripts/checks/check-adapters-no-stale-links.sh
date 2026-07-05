#!/bin/sh
# Adapter files (including the .mdc that markdown link-checkers skip) must carry no
# stale '../../' links, and any skill they name must exist on disk.
# Portable POSIX sh; zero runtime deps.
set -u
[ -d adapters ] || { echo "FAIL: adapters/ not found (run from repo root)"; exit 2; }
status=0
hits=$(grep -rnE '\.\./\.\.' adapters/ 2>/dev/null || true)
if [ -n "$hits" ]; then
  echo "FAIL: stale '../../' link(s) in adapters/:"; printf '%s\n' "$hits"; status=1
fi
for s in $(grep -rhoE 'skills/[a-z0-9-]+' adapters/ 2>/dev/null | sed -E 's#skills/##' | sort -u); do
  [ -d "skills/$s" ] || { echo "FAIL: adapter references missing skill '$s'"; status=1; }
done
if [ "$status" -eq 0 ]; then
  echo "ok: adapters carry no stale ../../ links"
fi
exit "$status"
