# Experiment log — first real cutover (Slice F executed), 2026-08-02

*Method: the shipped [cutover runbook](../../../docs/cutover-runbook.md), followed verbatim on the
first real consumer: a maintainer host that had been on the retired per-slug symlink mode since
2026-07-10 — 22 `~/.claude/skills/<slug>` links pointing into the live working tree. Outputs captured
verbatim; paths generalized (`$HOME`, `$PACK`).*

## Pre-state (the retired mode, live)

```text
$ ls -la ~/.claude/skills | head -3
lrwxr-xr-x  acceptance-tests-observable-outcomes -> $PACK/skills/acceptance-tests-observable-onestcomes/
lrwxr-xr-x  additive-default-off-feature-flags -> $PACK/skills/additive-default-off-feature-flags/
(22 such links; fallback record captured to cutover-fallback.txt before any change)
```

## The run — ordered log, verbatim

```text
TEARDOWN 2026-08-02T09:29:27Z legacy per-slug symlinks into $PACK
STANDUP 2026-08-02T09:29:39Z pinned @ db16894dc7478773ee4730673a4ec391689cee08 (excluded: acceptance-tests-observable-outcomes adversarial-lens-review definition-of-done-tooling environment-research)
BOOTCHECK_GREEN 2026-08-02T09:30:07Z METHODOLOGY OK — tier agent-methodology, 18 skill(s)
ROLLBACK_DRILL 2026-08-02T09:30:07Z legacy state restored (22 links)
TEARDOWN 2026-08-02T09:30:21Z legacy per-slug symlinks into $PACK (post-drill redo)
STANDUP 2026-08-02T09:30:21Z pinned @ db16894dc7478773ee4730673a4ec391689cee08 (post-drill redo)
BOOTCHECK_GREEN 2026-08-02T09:30:24Z METHODOLOGY OK — tier agent-methodology, 18 skill(s)
```

`REMOVE_FALLBACK` is deliberately absent: the runbook's soak ("days, not minutes") is running; the
fallback record stays and rollback remains one command until the operator logs that phase.

## What each phase proved

- **TEARDOWN scoping held.** The loop removed exactly the 22 links resolving into `$PACK` and
  nothing else (`~/.claude/skills` count went 22 → 0, no unrelated entries existed or were touched).
- **STANDUP with exclusion (REQ-12, first real use).** `install-consumer.sh` under
  `MAT_EXCLUDE_SKILLS` produced a read-only materialization of the pinned commit with 18 skills;
  `.excluded` records the four omitted slugs sorted; `.skillset` derived from the remainder.
  The four excluded slugs are the ones the extended-superpowers plugin already owns on this host —
  the duplication that motivated REQ-12.
- **BOOTCHECK_GREEN via a real session.** A headless `claude -p` fired the SessionStart hook
  (P13's mechanism, now on the real host, not an isolated config) and the out-of-tier boot check
  wrote `METHODOLOGY OK — tier agent-methodology, 18 skill(s)`.
- **Discovery at real scale, post-exclusion (P10's mechanism).**

  ```text
  $ claude plugin details agent-methodology
  Component inventory
    Skills (18)  additive-default-off-feature-flags, …, surgical-changes-with-checkpoints
  ```

  All 18 non-excluded skills list through the single symlink; none of the four excluded appear.
- **The rollback drill is a capability, not a hope.** Executed for real: the plugin symlink removed,
  all 22 legacy links recreated from the fallback record by the runbook's one-liner, verified, then
  the cutover redone — both drills in the log above. Redo exercised provisioning idempotence
  (existing materialization reused, hook dedup preserved a single SessionStart entry).

## Caveats, stated honestly

- The pack's own repo still surfaces all 22 skills project-locally when working *in* the repo —
  correct there (the skills are the artifact under development), irrelevant elsewhere.
- The exec-content review ran auto-approved (`BUMP_ASSUME_YES=1` inside `install-consumer.sh`, by
  design for provisioning); the pinned commit was the operator-reviewed merge of PRs #34/#35, so the
  review had already happened at merge time.
- `REMOVE_FALLBACK` pending; until then the retired mode is one command away by intent.
