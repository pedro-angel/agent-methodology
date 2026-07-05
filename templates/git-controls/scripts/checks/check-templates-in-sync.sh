#!/bin/sh
# The distributable copy under templates/git-controls/ must not drift from the root
# controls it mirrors: enforce byte-identity for the shared files. If there is no
# templates/git-controls/ (e.g. a repo that ADOPTED these controls into its own root),
# there is nothing to mirror and the check passes.
# Portable POSIX sh; zero runtime deps.
set -u
tpl=templates/git-controls
[ -d "$tpl" ] || { echo "ok: no $tpl/ to check"; exit 0; }
# Files that MUST stay byte-identical between the root and the distributable copy.
files=".pre-commit-config.yaml .markdownlint-cli2.yaml .github/workflows/checks.yml"
for s in scripts/checks/*.sh; do files="$files $s"; done
status=0
for f in $files; do
  if [ ! -f "$f" ]; then echo "FAIL: missing root file $f"; status=1; continue; fi
  if [ ! -f "$tpl/$f" ]; then echo "FAIL: $tpl/$f missing (template drifted from root)"; status=1; continue; fi
  cmp -s "$f" "$tpl/$f" || { echo "FAIL: $tpl/$f differs from $f"; status=1; }
done
if [ "$status" -eq 0 ]; then
  echo "ok: templates/git-controls mirrors root ($(printf '%s\n' $files | grep -c .) files)"
fi
exit "$status"
