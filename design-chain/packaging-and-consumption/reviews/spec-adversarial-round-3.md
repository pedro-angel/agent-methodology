# Spec adversarial review — round 3 (SPECS.md v3) → the lean pivot

*Date: 2026-07-18. Re-dispatched all three needs-fixes lenses against v3. All three converged on one
conclusion: v3's v2-round fixes over-reached into distributed-systems machinery a solo, on-demand,
few-hosts consumer does not need. v4 answers by **subtraction** — the anti-hubris move — not by adding more.*

## What round 3 confirmed resolved (across lenses)

The race in the boot check (round-2 B1/M4) is genuinely closed — the boot check reads only the symlink
target. REQ-10 no-artifacts, REQ-2b prose-handles, REQ-4a interrupt/retry, REQ-4b headless deny-path, and
REQ-8 teardown ordering are all delivered by AC text (completeness confirmed traceability complete, no scope
creep, all forks/slices/consumer-classes carried).

## What round 3 found — and why the fix is removal

| Finding (lens) | v4 disposition |
| --- | --- |
| **`CORRUPTED` is a tautology** — no `.git` in a read-only export, so `.pinned-sha` can't be recomputed against content; the check reduces to "40 hex chars" and its deny branch can never fire (df BLOCKER; test MAJOR — undefined oracle) | **REMOVED.** Read-only already prevents the accidental content-drift `CORRUPTED` targeted; tamper is explicitly not a boundary (F4/F5). Boot check = `MISSING` + `PARTIAL` only. |
| **Diff-hash approval key untestable** — an SHA-only impl passes every AC yet a same-SHA/different-baseline re-forward would auto-release unreviewed hooks (test BLOCKER) | **REMOVED** with the distributed approval record. Lean model: the operator reviews the diff at bump time and **sets each consumer's pin directly**; a worker installs the operator-provided pin. No record to key, distribute, or lock. |
| **Approval record has no home / delivery to off-host worker+UID** (df + comp MAJOR) | **REMOVED.** The worker's pin comes from operator provisioning, not a fetched record. |
| **Reaper not under lock; can delete an in-progress export / a generation a long session outlives** (df MAJOR ×2) | **SIMPLIFIED.** Retain the previous **one** materialization for rollback; reap older opportunistically at bump time. Concurrent-bump serialization and session-lease GC → **deferred residuals** (a solo maintainer does not run concurrent bumps; sessions are on-demand and short, ADR-0011). |
| **Fleet conformance floats (no REQ/AC; "blessed SHA" undefined)** (comp + df) | **REMOVED** — the operator knows each consumer's pin because the operator set it. Listed as a residual if the fleet ever grows. |
| **check-of-the-checker only at provision time; wiring can be removed post-provision** (df MAJOR) | **SCOPED honestly** — the guarantee is provision-time; continuous wiring verification is a deferred residual (the wiring is per-host, uncommitted; noted). |
| **AC precision** — pin the boot-check tokens, the ordered-log tokens, the reject-pattern/mode-marker strings, the no-artifacts scan patterns, AC-4b's one capturable artifact, AC-3c's "no second resolution" observable, AC-9's enumerated set = every deny signal + a remove-a-member→red meta-test, AC-6's working-tree predicate, AC-7's internal-consistency predicate, the named-host UID acceptance pass-condition (test MINORs) | **APPLIED** in v4's ACs. |

## Deferred residuals (documented, not silently dropped)

1. **Concurrent-bump serialization** (per-consumer lock) — not built; a single operator does not bump
   concurrently. Add a lock if bumps ever become multi-actor/automated.
2. **Session-lease / generation GC** — not built; keep one rollback copy, reap older at bump time. Revisit
   if long-lived sessions become common.
3. **Pin content-integrity (`CORRUPTED`)** — not built; read-only prevents accidental drift, tamper is not a
   boundary (F4/F5).
4. **Distributed approval record + fleet conformance** — not built; operator sets each pin after reviewing
   the diff. Revisit if hosts multiply or bumps automate.
5. **Signature verification** — deferred (F4).

Each residual is a place the design can grow **without rework** — the seams (a pin per consumer, a bump
step, a boot check) are the same; only the mechanism behind them would harden.

## Net

v4 is smaller than v3 and closes both round-3 BLOCKERs by removing their subject matter. The genuine-safety
properties (read-only pin, atomic publish, worker-installs-operator's-pin, loud `MISSING`/`PARTIAL` boot
check, reversible teardown-first cutover, mutation-tested deny paths) remain, each with a pinned-observable
AC. A single design-flaw re-check verifies the simplified model has no residual race before the spec advances.
