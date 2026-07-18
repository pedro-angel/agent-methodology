# Spec adversarial review — round 2 (SPECS.md v2)

*Date: 2026-07-18. Re-dispatched the three round-1 needs-fixes lenses (design-flaw/race, completeness,
testability) against v2. This ledger records what v2 fixed, what it reopened, and how v3 answers it.*

## Verdicts on v2

- **design-flaw/race: needs-fixes** — v2 closed M1/M2/M3/M5/M7, but reopened B1/M4: `REQ-5c` compared the
  target's SHA to "the consumer's recorded pin" — an undefined external record that races the non-atomic
  flip (false `DRIFTED`) or is vacuous.
- **testability/DoD: needs-fixes** — the "approved pin"/"disposition token" (the whole operator-gate +
  headless-trust model) had no pinned, testable form.
- **completeness: needs-fixes** — traceability structurally complete and no scope creep, but five guarantees
  (REQ-10 no-artifacts, REQ-2b prose-handles, REQ-4a atomicity, REQ-4b headless-refuses-unapproved, REQ-8
  teardown-vs-AC-6b ordering) were annotated as covered while the mapped AC text did not exercise them.

## Root fix in v3 — one local record + a concrete approval record

The two BLOCKERs are one problem: v2 kept a second SHA record. v3 removes it.

- **Single local source of truth.** The atomically-published **symlink target** is the only per-consumer
  record. The boot check is **integrity-only**, everything read from inside the target: symlink resolves
  (else `MISSING`); frozen auto-derived skill-set snapshot equals the actual skill dirs (else `PARTIAL`);
  `.pinned-sha` self-descriptor is well-formed and matches the target's own identity (else `CORRUPTED`). No
  external comparison → no race (B1/M4 closed). `DRIFTED` is retired: read-only + the frozen snapshot make
  silent content-drift structurally impossible; "on an old pin" is a fleet concern, not local integrity.
- **Approval record (operator/fleet-owned, separate from the per-consumer symlink).** The operator bump,
  only **after** the `hooks/`/scripts disposition clears, writes an approval keyed to
  `(resolved SHA, hooks/scripts diff-hash)`. A headless materialization (REQ-4b) reads it and **refuses**
  (`UNAPPROVED`) any pin without a valid record. This is testable and closes B2/B3 at the gate.
- **Fleet conformance** (are all hosts on the blessed SHA?) is an optional operator read-only observation
  comparing each consumer's target `.pinned-sha` to the approval record — never the boot check, never a race.

## Other v3 changes (by finding)

| Finding | Fix in v3 |
| --- | --- |
| df: reap TOCTOU (M6 restated) | REQ-4c: **grace-window/generation** reaping — retain the previous N approved materializations, reap by generation not an instantaneous liveness check; AC-6c asserts a referenced materialization is not reaped. |
| df: check-of-checker regress base case | REQ-5: assert the boot-check wiring's presence at **provision time** (fail provisioning), the terminating anchor; scope "cannot be silently absent" to that. |
| df: concurrent bumps unserialized | REQ-4a: per-consumer bump/materialize **lock** (serialize publish). |
| test: approved-pin/token form | REQ-4 + AC-3b/AC-5b: approval record keyed to (SHA, diff-hash); ACs (a) block w/o record, (b) same diff proceeds w/ record, (c) headless refuses UNAPPROVED, (d) record for A doesn't release B. |
| test+comp: AC-8 "exactly one mode" contradicts multi-mode INSTALL.md | AC-8: assert retired per-skill model **absent** AND exactly one **maintainer-own-host** mode (tag-pinned) named via a pinned mode-heading marker; other-people modes (copy/submodule/sync-bot) explicitly allowed. |
| test+comp: AC-5 un-runnable UID infra | AC-5 split: a **CI-runnable proxy** (interactive config + local-clone worker + distinct-`$HOME` standing in for the UID) feeds the gate; a **named-host acceptance run** (real separate UID) is a separate, labeled acceptance step. |
| test+comp: REQ-4a interrupt/retry untested | AC-3d: kill a bump between temp-materialize and publish → prior pin resolves (no `MISSING`), retry idempotent, partial reaped; boot check during a re-point never emits `MISSING`. |
| test+comp: REQ-10 no-artifacts unchecked | AC-9 gains a pinned scan asserting zero marketplace/signing artifacts in the base tree. |
| test: AC-9 under-collection | AC-9: assert the **enumerated** expected deny-path set is present (not just >0); meta-test empty→red; flip-the-return runs in the **standing** gate. |
| comp: REQ-2b prose-handles uncovered | AC-8 gains a pinned grep over the doc set for zero bare/namespaced invocation handles (paths only). |
| comp: REQ-4b headless-refuses-unapproved no deny path | AC-5b (above) + collected in AC-9. |
| comp: AC-6b ordering contradiction (teardown-first vs before-any-removal) | AC-6b scoped to the vendored/manifest/drift-guard fallback; per-slug teardown-precedes-stand-up asserted separately via an emitted ordered cutover log. |
| comp: AC-6 cross-repo scan not runnable here | AC-6 keeps only the `~/.claude/skills` resolve-and-classify runnable here; the consumer-tree scan is named as the consumer's own PR step. |
| test: AC-4c muddled | AC-4c: bump a SHA whose `skills/*/` = {X,Y,Z}; assert the frozen snapshot equals the set derived from the export's own dirs; no separate source list exists. |
| test: AC-7 self-referential | AC-7 reframed to a **stability** check: a frozen table of ≥3 labeled examples each with a recorded rationale; assert presence + internal consistency (labeled a doc check, not a functional classifier). |
| test: AC-2 brittle string | AC-2: content-hash-unchanged carries it; the permission-denied string is advisory. |
| test/comp: AC-1b wording; enumerate doc set; AC headers name secondary REQ | Applied. |
| test: M7 single-resolution untested | AC-3c gains a ref-moved-between-diff-and-export case. |

## Net

v3 removes the second SHA record (closing both BLOCKERs), pins the approval artifact so the worker-trust
guarantee is testable, and makes each AC's text exercise its guarantee. Round 3 re-verifies design-flaw and
testability on the model + the ACs.
