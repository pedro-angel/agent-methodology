# TASKS — build the tiered SHA-pinned read-only plugin model (v2)

> **For agentic workers:** execute slices in order; each is a reviewable propose-only PR. Mechanisms + pinned
> literals come verbatim from [DESIGN.md](DESIGN.md) v2; guarantees from [SPECS.md](SPECS.md) v5; the
> plan-review dispositions from [reviews/plan-adversarial-round-1.md](reviews/plan-adversarial-round-1.md).
> Working dir: the `agent-methodology` checkout. Every PR: anonymized, shellcheck/markdownlint green,
> DCO-signed, provenance trailer. Every scratch check runs under an isolated `HOME`/skills-root with a `trap`
> cleanup — **never touch the operator's live `~/.claude`**.

**Goal:** package the pack as the portable-tier plugin (+ an agent-tier scaffold) and ship the read-only
pinned consumption tooling, gate-tested. **Lean scope:** residuals R1–R5 are NOT built; the agent tier's
runtime consumption is deferred until a Claude-only skill exists.

## Global constraints

- POSIX sh, zero-dep for `tools/consume/*.sh` (shellcheck-clean). No consumer identifiers in this repo.
- Deny-test filenames **equal** their tokens (DESIGN); the collector fails closed on a missing member.
- This repo's gate covers **AC-1..AC-4c, AC-5, AC-7, AC-8, AC-9**. AC-5h/AC-6/AC-6b are out-of-repo
  acceptance items (Slice F is a runbook here; the cutover PR lands in the consumer repo).

---

### Slice A — Package the portable tier + scaffold the agent tier (REQ-1, REQ-2; AC-1, AC-1b)

- [ ] A1. Root `/.claude-plugin/plugin.json` (`name: agent-methodology`) over `skills/`.
- [ ] A2. `claude-tier/` scaffold: `.claude-plugin/plugin.json` (`name: agent-methodology-claude`),
      `README.md` ("Claude-only methodology lands here; consumption wired when the first such skill exists"),
      `skills/.gitkeep`. **No runtime consumption of this tier yet** (plan M5).
- [ ] A3. AC-1 under an **isolated** skills-root (`trap` cleanup): export the repo, symlink the portable
      tier, assert `claude plugin details` lists **every** skill — count **derived**, not the literal 22:

```bash
tmp=$(mktemp -d); H=$(mktemp -d); trap 'rm -rf "$tmp" "$H"' EXIT
git archive HEAD | tar -x -C "$tmp"; n=$(ls -1d skills/*/ | wc -l | tr -d ' ')
mkdir -p "$H/.claude/skills"; ln -sfn "$tmp" "$H/.claude/skills/zzA"
CLAUDE_CONFIG_DIR="$H/.claude" claude plugin details zzA | grep -qE "Skills \($n\)" || echo FAIL-count
```

Expected: no `FAIL-*`. *(If `CLAUDE_CONFIG_DIR` isolation is unavailable, use a uniquely-named `zzA-<rand>`
link in the real root and remove it in the trap; still derive `$n`.)* If the mixed export root is rejected,
apply DESIGN's `git archive <sha> skills .claude-plugin` fallback.

- [ ] A4. AC-1b: both manifests **parse** and carry their `name` from one `HEAD`:
      `git cat-file -p HEAD:.claude-plugin/plugin.json | grep -q '"agent-methodology"'` and the `claude-tier`
      one carries `agent-methodology-claude`.
- [ ] A5. PR **Slice A** (additive, default-off).

### Slice B-materialize — `materialize.sh` + its tests (REQ-3, REQ-4a; AC-2, AC-4c)

- [ ] Bm1. `tools/consume/materialize.sh` per DESIGN (pipefail archive, **hash** fidelity compare, `.skillset`
      derive, `chmod -R a-w`, atomic `mv -T`; no `.pinned-sha`).
- [ ] Bm2. Tests (each mutation-verified — normal asserts deny, return-inverted variant reddens):
      `t_readonly_export` (AC-2: no `.git`; write → non-zero + content hash intact),
      `t_export_fidelity_mismatch` (AC-2: a truncated file fails the produce step),
      `t_skillset_derived` (AC-4c: `.skillset == basename skills/*/`; and a repo-wide scan finds **no** tracked
      `*.skillset`).
- [ ] Bm3. Land `scripts/checks/check-consume-deny-paths.sh` **skeleton** now (collects present tests, notes
      "set completes in Slice D") so tests are gate-collected from their first PR. `shellcheck` clean. PR.

### Slice B-bump — `bump.sh` + its tests (REQ-4, REQ-4c; AC-3, AC-3b, AC-3c)

- [ ] Bb1. `tools/consume/bump.sh` per DESIGN (fetch untrusted, resolve-once vs `--intended-sha`, `--force`
      refuse, exec-diff review + operator confirm, materialize same SHA, non-greedy reap keeping
      current+previous).
- [ ] Bb2. Tests: `t_sha_mismatch` (AC-3c: resolved ≠ intended — incl. a fetch-exits-0-but-diverges input —
      fails loud), `t_force_refused` (AC-3c), `t_first_resolution_wins` (AC-3c: a tag moved after resolution
      does not change the export), `t_bump_content` (AC-3: new pin's content differs and loads; old pin dir
      unchanged), `t_diff_review` (AC-3b: hooks/scripts change → diff presented + pin-set gated on confirm;
      doc-only → empty diff; first bump → diff vs empty tree), `t_atomic_interrupt` (AC-3d: kill between
      export and publish → prior pin resolves via `readlink`; retry idempotent; temp gone),
      `t_reap_preserves_current_previous` (M14: a reap never deletes current/previous), `t_add_skill_bump`
      (AC-1 2nd clause: bump to a SHA adding a skill → `.skillset` re-derived, no new symlink). PR.

### Slice B-bootcheck — `bootcheck.sh` + its tests (REQ-5; AC-4)

- [ ] Bc1. `tools/consume/bootcheck.sh` per DESIGN (token **last**, stderr, MISSING/PARTIAL).
- [ ] Bc2. Tests `t_missing`, `t_partial` — assert the stderr line matches `^METHODOLOGY .* (MISSING|PARTIAL)$`
      and exit non-zero; mutation-verified. PR.

### Slice C — Provisioning + tier-independent wiring (REQ-5, REQ-6; AC-4b, AC-5)

- [ ] C0. **Probe P13** (precondition): does a headless `claude -p` under a provisioned config fire the
      user-level `SessionStart` hook + write the named log? Capture the result; if no, downgrade AC-4b to
      "wiring installed + named start command writes the log" and document the trigger.
- [ ] C1. `tools/consume/install-consumer.sh` per DESIGN (per-consumer-unique root, portable symlink,
      `bootcheck.sh` + `SessionStart` hook **outside any tier**, named log, assert-wiring-or-fail).
- [ ] C2. Tests: `t_wiring_absent_at_provision`; AC-5 proxy — install for `interactive` + a `local-clone
      worker` + a `distinct-$HOME` UID stand-in, assert each boot-checks green and two consumers on one
      host+UID get **distinct** roots; **AC-5 negative** — the worker variant fed a *ref* (not a SHA)
      **errors**, and a static grep of the worker path finds no `rev-parse`/`fetch` (it resolves none). AC-4b
      per P13: fresh start on a broken consumer writes the token to the named log with no manual `bootcheck`.
- [ ] C3. Register C's tests in the collector. **AC-5h** (real separate-UID on a named host) recorded as a
      named out-of-repo acceptance step (start command + pass condition — owner's evidence directive). PR.

### Slice D — Complete the CI/DoD deny-path gate (REQ-11; AC-9)

- [ ] D1. Finalize `check-consume-deny-paths.sh`: enumerated set `{t_missing, t_partial, t_sha_mismatch,
      t_force_refused, t_first_resolution_wins, t_export_fidelity_mismatch, t_reap_preserves_current_previous,
      t_wiring_absent_at_provision}`; fail closed on empty/missing; meta-test that removing a member reddens.
- [ ] D2. Add the collector + a `shellcheck` hook to `.pre-commit-config.yaml`; **byte-mirror both the
      collector AND the modified `.pre-commit-config.yaml`** into `templates/git-controls/` (M11).
- [ ] D3. AC-9 negative scan (pinned globs, DESIGN): zero marketplace/signing artifacts. `pre-commit run
      --all-files` green. PR.

### Slice E — Docs + placement (REQ-2b, REQ-7, REQ-9; AC-7, AC-8)

- [ ] E1. `INSTALL.md`: add the pinned own-host marker heading; keep other-people modes.
- [ ] E2. `adapters/claude/CLAUDE.md`: replace per-slug Install steps with a pointer to the new mode.
- [ ] E3. `docs/placement.md`: criteria sections + the frozen table (one row per tier + a promotion row).
- [ ] E4. AC-8 (pinned regexes, DESIGN): zero retired-model matches; exactly one own-host marker; zero
      namespaced handles in prose; a non-Claude path-read of `skills/<slug>/SKILL.md` resolves. AC-7: each row's
      tier ∈ {portable, agent, project} and its rationale references that tier's criterion. PR.

### Slice F — Cutover **runbook** (REQ-8; AC-6/AC-6b tracked out-of-repo)

- [ ] F1. Write the reusable runbook: the ordered-log contract (`TEARDOWN` ≺ `STANDUP` ≺ `BOOTCHECK_GREEN` ≺
      `REMOVE_FALLBACK`), teardown-first of legacy per-slug symlinks, stand-up + boot-check-green **before**
      any removal, and the rollback drill. **The actual de-vendoring is a referenced downstream PR in the
      consumer's repo** over a **named finite** consumer set (BRIEF non-goal here). AC-6/AC-6b are asserted in
      that PR, not this repo's CI.

## Definition of Done

- **This repo (CI):** AC-1..AC-4c, AC-5, AC-7, AC-8, AC-9 green; the deny-path gate collects the full set;
  `definition-of-done` reports GO for scope "A–E merged, CI green".
- **Acceptance (out-of-repo):** AC-5h (named-host UID), AC-6, AC-6b in the consumer/host environment.
- Residuals R1–R5 remain documented, not built.

## Decision log

- P-1 (plan round 1): defer the empty agent tier's runtime consumption (M5); Slice F is a runbook, the
  consumer de-vendoring is downstream (M9); DoD scope split repo-CI vs acceptance (M10).
