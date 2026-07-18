# Spec adversarial review — round 1 (SPECS.md v1)

*Date: 2026-07-18. Method: `extended-superpowers:adversarial-review` — four fresh reviewers, one binding spec
lens each (factual-grounding, completeness, design-flaw/race, testability/DoD), each tasked to refute. This
ledger records the findings and how SPECS v2 answers them. Dispositions are the author's.*

## Verdicts

- **factual-grounding: ready** — grounding holds; all findings are citation-precision MINORs.
- **completeness: needs-fixes** — every fork has a REQ, but three decided guarantees lacked ACs.
- **design-flaw/race: needs-fixes** — the bump is not atomic; the exec gate is a no-op for the headless worker.
- **testability/DoD: needs-fixes** — several ACs unmeasurable or happy-path only.

## BLOCKER / MAJOR → disposition in v2

| # | Lens | Finding | Fix in v2 |
| --- | --- | --- | --- |
| B1 | design-flaw | REQ-5(b) two-SHA boot check is racy (false DRIFTED mid-bump) or vacuous | **REQ-5 rewritten:** the bump publishes atomically and the boot check reads **one** consistent snapshot — the symlink target — whose SHA self-descriptor and expected-set snapshot are **frozen inside the read-only materialization**. No second racing record. New REQ-4a requires atomic publish. |
| B2 | design-flaw | Exec-content gate is a no-op for the headless fresh-clone worker (no prior pin, no human) | **REQ-4/REQ-4b split:** an **operator bump** (human) reviews the hooks/scripts diff and emits an *approved pin*; **automated materialization** (host/worker/UID, incl. headless) only ever installs an already-approved pin — no in-worker human gate. First approval diffs against empty. |
| B3 | testability | Exec-content gate has no AC; "human review" non-mechanical | **AC-3b:** an operator bump whose `hooks/`/scripts differ from the approved pin **blocks** (non-zero, requires a recorded disposition token); a doc-only bump proceeds. Assert the block, not just that a diff printed. |
| M1 | design-flaw | Re-point not atomic (rm-then-ln window → MISSING false-alarm) | REQ-4a: publish via atomic replace (`mv -T` a prepared symlink); no no-symlink window. |
| M2 | design-flaw | Interrupted bump leaves an orphaned partial read-only dir; retry wedged | REQ-4a: all-or-nothing — materialize into a unique temp path, publish atomically, retry idempotent, reap unreferenced partials. |
| M3 | design-flaw | Snapshot storage undefined → can drift from content | REQ-5: snapshot lives **inside** the read-only materialization, frozen with the content it describes. |
| M4 | design-flaw | Two competing "pins of record" (REQ-3 vs REQ-5b) | REQ-3/5: the atomically-published symlink target is the single source of truth; the in-materialization SHA is a self-descriptor, not a second anchor. |
| M5 | design-flaw | Per-consumer path collision when a host+UID runs two consumers | REQ-6: each consumer materializes under a **per-consumer-unique root**; reconcile with the cross-host path residual. |
| M6 | design-flaw | Cleanup of old materializations unassigned (disk leak, rollback loss, delete-races-session) | REQ-4c: reap only a materialization no live symlink/session references; retain N-1 for rollback. |
| M7 | design-flaw | Diff-vs-ship TOCTOU (ref re-resolves between review and archive) | REQ-4: resolve **one** SHA once, use it for the diff, the archive, and the recorded pin; forbid re-resolution. |
| M8 | design-flaw/testability | Boot-check wiring is itself uncommitted per-host; can be silently absent | REQ-5 + AC-4b: anchor the check in base provisioning present on every consumer; add a check-of-the-checker AC (a drifted consumer fails on a *fresh start*, not only when the script is hand-run). |
| M9 | completeness/testability | REQ-1 (two tiers, one tag) has no AC | AC-1b: both tiers carry a manifest, resolve from one tag, one bump moves both; "co-reviewed" dropped as unverifiable. |
| M10 | completeness/testability | REQ-8 reversibility (green-before-remove, working rollback, teardown-first) unverified | AC-6b: assert boot-check-green-on-every-consumer before removal; rollback restores; teardown-first of legacy per-slug symlinks added as a REQ-8 step. |
| M11 | testability | `--force` refusal + fetch-exit-0-divergence untested | AC-3c: a `--force` bump exits non-zero without re-pointing; a fetch that exits 0 with SHA divergence still fails loud. |
| M12 | testability | Auto-derived expected-set (REQ-5) untested | AC-4c: mutating the materialization's skills regenerates the snapshot; a hand-edit to the snapshot is rejected/overwritten. |
| M13 | testability | "human-visible message" unmeasurable | REQ-5/AC-4: pin the channel (**stderr**) and fault tokens (`MISSING`/`DRIFTED`/`PARTIAL`). |
| M14 | testability | Three consumer classes only doc-checked | AC-5: execute materialize+boot-check on each real consumer class and assert green (battle-testing). |
| M15 | testability | REQ-9 only the negative grep; not "exactly one mode" | AC-8: enumerate the doc set, pin the reject-pattern, assert exactly one install mode present. |
| M16 | testability | AC-7 doc-existence masquerading as functional | AC-7: named criteria sections + a fixed table of labeled example lessons with expected tier; assert the routing (determinism). |
| M17 | testability | AC-1 not pinned to a CLI version | AC-1: pin `claude` 2.1.214 (or a version-stable interface). |
| M18 | testability | Mutation/deny-path tests not wired into the CI/DoD gate | AC-9: the deny-path tests are collected by the gate and fail closed when zero are collected; split "mutation-verified" into assert-deny **and** flip-the-return-until-red. |

## MINORs (folded)

Citation precision (factual-grounding): REQ-2 "add-mid-stream" → "add-then-fresh-read"; the `<tier>:<slug>`
namespace form is attributed to the F2 decision (P3 is a reconstruction), not P5/P10; "surfacing" scoped to
"listed by `plugin details` with the plugin loaded"; REQ-5 snapshot marked *design, not proven by P9*; REQ-4
"pre-checkout diff" → "pre-acceptance diff (`git diff <old> <new> -- hooks scripts`)" (P7's export has no
checkout); AC-3 moved-tag labeled a design target (proven claim scoped to the rev-parse compare); REQ-8/AC-6
phrased generically — a consumer's vendored state is not verifiable from within this repo, so it names the
model, not a specific repo. Structural: added a `## Traceability` table; REQ-10 reduced to the checkable
negative (no marketplace/signing artifacts shipped) + a non-verifiable note; the path-not-handle ruling
promoted to REQ-2b with a grep AC; agent-tier contents enumerated; a shellcheck/POSIX AC added; AC-2 given a
concrete assertion + threat-model bound; AC-6 given a resolve-and-classify command.

## Net

v2 turns the bump into a single atomic publish with a frozen in-materialization snapshot, splits the
operator gate from headless materialization (closing the worker exec-gate hole), and gives every REQ an
executable AC plus a traceability table. Round 2 re-dispatches the three needs-fixes lenses.
