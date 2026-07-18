# Plan adversarial review — round 1 (DESIGN v1 + TASKS v1)

*Date: 2026-07-18. Three plan lenses (spec-coverage+guardrails, testing+trackability, sequencing+anti-hubris)
via `extended-superpowers:adversarial-review`. Structure held — dependency order acyclic (A→B→C→D→E, cutover
last), scope-creep clean (no residual R1–R5 built), all 15 REQs mapped. The findings are executability +
restraint, not rework. v2 (DESIGN + TASKS) applies them.*

## BLOCKER / MAJOR → disposition in v2

| # | Lens | Finding | v2 |
| --- | --- | --- | --- |
| B1 | coverage + testing | Boot-check output `METHODOLOGY <token>: <msg>` (token first) can't match AC-4's token-last `$`-anchored regex — the gate could never go green. | **Format fixed** to token-last: `METHODOLOGY <msg> <TOKEN>`; AC-4 regex unchanged. |
| B2 | testing | AC-5 "worker resolves no SHA" proven only by output-equality (passes even if it resolved). | **Prove the negative:** feed the worker path a *ref* (not a SHA) → assert it refuses; plus a static grep of the worker path for `rev-parse`/`fetch`. |
| B3 | coverage + testing | AC-4c (`.skillset` derive-equality + "no hand-maintained skillset list outside an export") has no task and no scan mechanism. | Added the derive-equality test **and** a repo-wide negative scan (pinned pattern) in DESIGN + a Slice-B step. |
| M1 | coverage + testing | AC-3, AC-3b, AC-3d are commented "see tests/" but no test exists — content-change, diff-review-gate, and interrupt/atomicity rest on SPEC-phase probes, not the shipped scripts. | Added runnable tests `t_bump_content`, `t_diff_review` (3 cases incl. empty-tree first bump), `t_atomic_interrupt`, exercised against `bump.sh`/`materialize.sh`. |
| M2 | coverage + testing | Produce-time fidelity floor (`tar -t` path-set vs `find`) misses a byte-level truncation. | **Tree/per-file hash compare is now the required mechanism**, not "stronger". |
| M3 | testing | AC-2 verify one-liner is non-runnable (undefined vars, multi-glob `test`, one-match redirect). | Replaced with a real `t_readonly_export` test. |
| M4 | testing | A3 greps the operator's **live** `~/.claude` (slug collision + residue). | A3 runs under an isolated `HOME`/skills-root with a `trap` cleanup; the skill count is **derived** (`ls -1d skills/*/`), not the literal `22`. |
| M5 | testing + sequencing | The skill-less `claude-tier/` is materialized, loaded, symlinked, boot-checked, cut over — empty-tier machinery for zero skills; and its empty-plugin load is unprobed. | **Defer the agent tier's runtime consumption.** Keep only the git scaffold (manifest + README + `.gitkeep`, AC-1b existence). Consumption wires the **portable tier only** until a Claude-only skill lands (already-decided model, one future symlink). Rationale stated. |
| M6 | testing | "mutation-verified (goes red when the fail-closed return is flipped)" has no mechanism. | DESIGN specifies the **mutation harness**: each deny-test runs the guard normal (assert deny) and against a return-inverted variant (assert the suite reddens). |
| M7 | testing + sequencing | `t_fetch_exit0_diverges` targets a fetch path `bump.sh` doesn't have — vacuous / a rename of `t_sha_mismatch`, over-counting the set. | `bump.sh` **does** fetch (that's how a new ref arrives); the fetch exit code is non-load-bearing because the SHA-vs-intended compare gates. The two collapse into one guard: **dropped `fetch-exit0-diverges` as a separate member**; `t_sha_mismatch` exercises both a direct mismatch and a fetch-exits-0-but-diverges input. |
| M8 | testing | AC-4b names no start command; the CI proxy would "verify" auto-fire by calling `bootcheck` directly (assertion, not exercise); headless SessionStart-fire is unprobed. | Name the start command (`claude -p` under the provisioned config); **add probe P13** (does a headless session fire a user-level SessionStart hook + write the named log?) before asserting AC-4b; honest-downgrade if it does not. |
| M9 | coverage + sequencing | Slice F ships the **consumer's de-vendoring** — a BRIEF non-goal, wrong repo, unbounded "every consumer". | Slice F here ships only the **reusable cutover runbook + the ordered-log contract**; the actual de-vendoring is a **referenced downstream PR in the consumer's repo** over a **named finite** consumer set. |
| M10 | testing + sequencing | DoD asserts "all ACs GO" but AC-5h/6/6b run out-of-repo — GO unreachable here; Slice F cross-repo dependency breaks "each slice its own PR". | DoD scope split: this repo's gate covers **AC-1..4c, 5, 7, 8, 9**; AC-5h/6/6b are **tracked out-of-repo acceptance**. Slice F labeled an operational rollout, not a code PR. |
| M11 | coverage + testing | Templates-mirror: D2 adds hooks to root `.pre-commit-config.yaml` but only mirrors the collector → `check-templates-in-sync` reddens. | D2 **also byte-mirrors the modified `.pre-commit-config.yaml`** into `templates/git-controls/`. |
| M12 | testing | DESIGN leaves AC-8 reject-regex, the one-mode marker string, AC-9 signing globs, AC-4c pattern, AC-6 realpath check unfixed — self-authored regex vs self-chosen marker isn't an independent guard. | All literals **pinned in DESIGN**. |
| M13 | sequencing | Slice B bundles 3 scripts + 7 tests + integration — too big for one PR. | Slice B **split** into B-materialize / B-bump / B-bootcheck, each its own PR. |
| M14 | sequencing | The greedy `rm -rf <root>.*` reap could delete the rollback target; no deny-path guards it. | Non-greedy reap (exclude current+previous explicitly) + new test `t_reap_preserves_current_previous`, enumerated in the gate set. |

## MINORs (folded)

Collector skeleton lands in the first slice that adds tests (not only Slice D), else the "registered or
fail-closed" constraint is unenforceable early · A4 asserts each manifest parses + carries its `name` ·
AC-1 second clause (bump-adds-skill → `.skillset` re-derived, no new symlink) added · `.pinned-sha` **dropped**
(unread) · "≥3 example rows" justified as **one row per tier {portable, agent, project} + a promotion row**,
and AC-7 asserts each tier value appears · deny-test **filenames == tokens** so the collector's mapping can't
false-red/green.

## Net

v2 makes every AC runnable against the shipped scripts, pins the guard literals, defers the empty agent
tier's consumption (keeping the decision as a scaffold), and hands the consumer de-vendoring back to the
consumer's repo where the BRIEF put it. Structure and scope were already sound; v2 makes them executable.
