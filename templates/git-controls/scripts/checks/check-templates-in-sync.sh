#!/bin/sh
# The distributable copy under templates/git-controls/ must not drift from the root
# controls it mirrors. If there is no templates/git-controls/ (e.g. a repo that ADOPTED
# these controls into its own root), there is nothing to mirror and the check passes.
# Portable POSIX sh; zero runtime deps.
set -u
tpl=templates/git-controls
[ -d "$tpl" ] || { echo "ok: no $tpl/ to check"; exit 0; }

status=0

# Byte-identical: the pre-commit contract, the markdownlint config, and every validator.
files=".pre-commit-config.yaml .markdownlint-cli2.yaml"
for s in scripts/checks/*.sh; do files="$files $s"; done
for f in $files; do
  if [ ! -f "$f" ]; then echo "FAIL: missing root file $f"; status=1; continue; fi
  if [ ! -f "$tpl/$f" ]; then echo "FAIL: $tpl/$f missing (template drifted from root)"; status=1; continue; fi
  cmp -s "$f" "$tpl/$f" || { echo "FAIL: $tpl/$f differs from $f"; status=1; }
done

# The CI workflow is compared with pinned-action refs normalized out: Dependabot bumps the
# `uses: …@<sha> # <tag>` in the ROOT workflow only (it doesn't manage the template copy),
# so a lone version bump must not trip this. Any change to the workflow's structure or logic
# is still caught.
wf=".github/workflows/checks.yml"
if [ ! -f "$wf" ] || [ ! -f "$tpl/$wf" ]; then
  echo "FAIL: missing $wf or $tpl/$wf"; status=1
else
  a=$(mktemp) || exit 2
  b=$(mktemp) || exit 2
  trap 'rm -f "$a" "$b"' EXIT INT TERM
  sed -E 's#(uses:[^@]*@)[0-9a-f]{40}.*#\1PINNED#' "$wf"      > "$a"
  sed -E 's#(uses:[^@]*@)[0-9a-f]{40}.*#\1PINNED#' "$tpl/$wf" > "$b"
  cmp -s "$a" "$b" || { echo "FAIL: $tpl/$wf differs from $wf (beyond a pinned-version bump)"; status=1; }
fi

if [ "$status" -eq 0 ]; then
  echo "ok: templates/git-controls mirrors root (configs, validators, workflow logic)"
fi
exit "$status"
