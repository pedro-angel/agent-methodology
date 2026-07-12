#!/usr/bin/env bash
# Project DoD gate for the weigh-before-stance extension. Reads dod.config,
# runs every required check against recorded artifacts; the author never
# self-certifies. Working artifact of the design chain (not shipped).
set -uo pipefail
root=$(git rev-parse --show-toplevel); cd "$root"
cfg=design-chain/eod-weigh-before-stance/dod.config
req(){ grep -qE "^$1[[:space:]]*=[[:space:]]*required" "$cfg"; }
nogo=0
res(){ if [ "$2" -eq 0 ]; then echo "  GO    $1"; else echo "  NO-GO $1"; nogo=1; fi; }
echo "Definition-of-Done gate ($cfg)"

if req ci_green; then
  python3 -m pre_commit run --all-files >/tmp/dod-ci.log 2>&1; res "ci_green (pre-commit --all-files)" $?
fi

if req machine_acs; then
  ok=0
  f=skills/evidence-over-deference/SKILL.md
  d=$(sed -n 's/^description: //p' "$f")
  [ "$(grep -c '^description:' "$f")" = 1 ] || ok=1
  case "$d" in "Use when "*"; their decision still wins.") : ;; *) ok=1 ;; esac
  [ "$(printf %s "$d" | grep -o '—' | wc -l | tr -d ' ')" = 1 ] || ok=1
  printf %s "$d" | sed 's/—.*//' | grep -qE '\b(propos[a-z]*|direction|framing)\b' || ok=1
  printf %s "$d" | perl -ne 'exit 1 unless /—[^—;]*weigh[a-z]*[^—;]*before/' || ok=1
  for p in "Verify a checkable premise" "Challenge once, with evidence and an alternative" "The human's decision wins after being heard" "Challenge is symmetric" "No relitigating" "One clear statement, not a filibuster" "concede on evidence without performative agreement"; do
    grep -qF "$p" "$f" || ok=1
  done
  dir='\b(propos[a-z]*|direction|framing)\b'
  awk '/^### \[evidence-over-deference\]/{f=1;next} /^### /{f=0} f' AGENTS.md | grep -qE "$dir" || ok=1
  grep 'evidence-over-deference' README.md | grep -q 'weigh' || ok=1
  grep -A1 'evidence-over-deference' adapters/cursor/methodology.mdc | grep -q 'weigh' || ok=1
  awk '/^### evidence-over-deference/{f=1;next} /^### /{f=0} f' adapters/copilot/copilot-instructions.md | grep -q 'weigh' || ok=1
  grep -q 'evidence-over-deference/SKILL.md' skills/honest-reframing-over-overclaiming/SKILL.md || ok=1
  [ "$(git show --name-only --format= HEAD | sort | paste -sd, -)" = "AGENTS.md,README.md,adapters/copilot/copilot-instructions.md,adapters/cursor/methodology.mdc,skills/evidence-over-deference/SKILL.md,skills/honest-reframing-over-overclaiming/SKILL.md" ] || ok=1
  git log -1 --format=%B > /tmp/dod-msg.txt
  bash scripts/checks/check-commit-trailer.sh /tmp/dod-msg.txt >/dev/null || ok=1
  grep -q 'design-chain/eod-weigh-before-stance/evals' /tmp/dod-msg.txt || ok=1
  res "machine_acs (AC-2..AC-8 batch)" $ok
fi

if req acceptance_green; then
  ok=0
  h=$(git hash-object skills/evidence-over-deference/SKILL.md)
  for s in S1 S2 S3 S4 S5 S6 S7 S8 S9 routing; do
    latest=$(ls design-chain/eod-weigh-before-stance/evals/${s}-attempt*-verdict.md 2>/dev/null | sort -V | tail -1)
    [ -n "$latest" ] || { echo "      missing verdict: $s"; ok=1; continue; }
    grep -q "skill-hash: $h" "$latest" || { echo "      stale hash: $latest"; ok=1; }
    grep -qE 'verdict: PASS|verdict.*PASS' "$latest" || { echo "      not PASS: $latest"; ok=1; }
  done
  res "acceptance_green (10 recorded non-author verdicts, hash-bound)" $ok
fi

if req grooming; then
  if git show --name-only --format= HEAD | xargs grep -lnE 'TBD|FIXME|XXX' 2>/dev/null | grep -q .; then
    res "grooming (no placeholders in shipped files)" 1
  else
    res "grooming (no placeholders in shipped files)" 0
  fi
fi

for c in lint coverage telemetry; do
  if req "$c"; then echo "  NO-GO $c (required but no check defined)"; nogo=1; fi
done
echo
if [ "$nogo" -eq 0 ]; then echo "DoD: GO"; exit 0; fi
echo "DoD: NO-GO"; exit 1
