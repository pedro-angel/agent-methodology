# DESIGN — how the tiered SHA-pinned read-only plugin model is built (v2)

*Consumes: [SPECS.md](SPECS.md) (v5). Feeds: [TASKS.md](TASKS.md). Date: 2026-07-18. v2 applies plan review
round 1 ([reviews/plan-adversarial-round-1.md](reviews/plan-adversarial-round-1.md)): boot-check format
fixed, all guard literals pinned, produce-time fidelity is exit-checked, `bump.sh` fetches, the empty agent
tier's runtime consumption is deferred (scaffold only), and the mutation harness + negative scan are
specified. The HOW; guarantees are SPECS's. Anonymized; consumer-specific cutover lives in the consumer repo.*

## Mechanism overview

The **portable tier** is a `.claude-plugin/plugin.json` at the repo root over the existing `skills/`
(REQ-1/2), consumed via one symlink `~/.claude/skills/agent-methodology` → a read-only export. The **agent
tier** `claude-tier/` is scaffolded (manifest + README + empty `skills/`) so the F1/F2 decision is
git-addressable, but its **runtime consumption is deferred** until a Claude-only skill exists — wiring an
empty plugin through materialize/symlink/boot-check on every consumer is machinery for zero skills (plan
round-1 M5); adding it later is one already-designed symlink. A consumer **materializes** a pinned commit
into a per-consumer read-only export (`git archive`, no `.git`); a **bump** re-points the symlink after the
operator reviews the hooks/scripts diff; a tier-independent **boot check**, installed into the consumer's
config at provision time, asserts the tier resolves and is complete on every session start.

## Pinned literals (SPECS: "every pattern/token is a literal DESIGN must fix")

- Boot-check line: `printf 'METHODOLOGY %s %s\n' "$msg" "$TOKEN"` on **stderr**, `$TOKEN ∈ {MISSING, PARTIAL}`,
  matching AC-4 `^METHODOLOGY .* (MISSING|PARTIAL)$` (token **last**).
- INSTALL.md own-host mode marker heading (exact): `## Tag-pinned plugin (maintainer's own hosts)`.
- AC-8 retired-model reject regex: `(ln -s.*~/.claude/skills/[^ ]*/|for d in .*skills.*ln -sfn)` (the per-slug
  symlink loop) — zero matches over the doc set.
- AC-8 namespaced-handle regex: `` `agent-methodology(-claude)?:[a-z-]+` `` — zero matches in prose.
- AC-9 marketplace/signing artifact globs: `marketplace.json`, `**/*.sig`, `**/*.asc`, and the key
  `"marketplace"` in any `.claude-plugin/*.json` — zero matches.
- AC-4c hand-maintained-skillset reject pattern: a `.skillset`-shaped list committed **outside** an export
  dir, i.e. any tracked file named `*.skillset` (the only legitimate one is produced read-only, untracked).
- AC-6 working-tree predicate: `git -C "$(readlink -f <target>)" rev-parse --is-inside-work-tree` **fails**.

## Plugin manifests (REQ-1, REQ-2; AC-1, AC-1b)

Portable `/.claude-plugin/plugin.json`: `{"name":"agent-methodology","version":"0.0.0","description":"…"}`
over the repo-root `skills/`. Agent `claude-tier/.claude-plugin/plugin.json`: `name:"agent-methodology-claude"`
(scaffold). **Packaging-verify (extends P10):** the portable check re-runs `claude plugin details` against a
**full-repo export root** (extra files beside `.claude-plugin/`+`skills/`) and confirms every skill still
lists; if the mixed root is rejected, fall back to `git archive <sha> skills .claude-plugin`.

## `materialize.sh <checkout> <sha> <out-dir>` (REQ-3, REQ-4a; AC-2) — the pure producer

*(Reconciled to the shipped implementation: it produces a verified read-only directory ONLY; the atomic
symlink publish moved to the caller — see below.)*

1. Verify `<sha>` is a commit (`git rev-parse --verify`); refuse if `<out-dir>` already exists.
2. `git archive <sha> >"$tar"` then `tar -x -f "$tar" -C "$tmp"` as **two exit-checked steps** (POSIX sh has
   no `pipefail`, so a piped `archive | tar` would hide a mid-stream failure).
3. **Fidelity = those two exit codes + git's object integrity (AC-2).** `git archive` of a
   rev-parse-verified, content-addressed commit is deterministic; a *complete* extraction IS the commit's
   content, so a truncated / disk-full export fails loud on the `tar` exit. *(An earlier per-file
   `ls-tree`/`hash-object` compare was dropped in implementation — it false-refused non-ASCII paths,
   symlinks, and `export-ignore` entries, and added nothing over git's own integrity.)*
4. Derive `"$tmp/.skillset"` = `basename` of each `"$tmp"/skills/*/` (sorted; never hand-authored — AC-4c).
5. `chmod -R a-w "$tmp"`; publish by `mv "$tmp" "<out-dir>"` (rename within one fs), then a **post-publish
   check** that `<out-dir>/.skillset` exists (closes the `mv` TOCTOU). The signal trap `exit`s, not just
   cleans. No `.pinned-sha` (unread).

Interrupt-safe: everything is in `$tmp` until the final `mv`; an interrupt leaves prior state intact and
reaps the temp. **The atomic symlink publish is the CALLER's job** (`bump.sh` / `install-consumer.sh`), via
`ln -sfn "<out-dir>" "$symlink"` — portable across BSD+GNU (**`mv -T` is GNU-only; it errors on macOS**).
Residual: BSD `ln -sf` is unlink-then-create, a sub-millisecond window; a session starting in it gets a loud
`MISSING` (never silent) and the next session is fine — acceptable for the on-demand solo model.

## `bump.sh <checkout> <ref> <intended-sha> <mat-root> <symlink> [remote]` (REQ-4, REQ-4c; AC-3, AC-3b, AC-3c)

*(Reconciled to the shipped implementation: positional args; the atomic publish + reap live here since
`materialize.sh` is the pure producer.)*

1. Reject `--force` anywhere in argv, and refuse a `<remote>` that looks like an option (`-*` — option
   injection) (AC-3c). `git -C <checkout> fetch --tags <remote>` (only if given) **may exit 0 on a
   clobbered/rejected tag** — its exit code is **not trusted**; resolve `got=$(git rev-parse --verify
   "<ref>^{commit}")` **once** and **fail loud if `got != <intended-sha>`** (AC-3c — one SHA-vs-intent
   compare covers a moved tag and a lying fetch).
2. Exec-content review (AC-3b): diff the previous pin → `$got` over `scripts hooks claude-tier`. The review
   **base** is the previous pin ONLY IF it still resolves to a commit here; a dangling/foreign symlink or a
   GC'd/shallow base falls back to the **empty tree = a full review**, never a silently-empty diff — the gate
   **fails closed** (round-1 BLOCKER: a swallowed `git diff` error had skipped the review). A non-empty
   exec-diff **blocks until the operator confirms**; a **doc-only (empty) diff proceeds without a prompt**
   (AC-3b). `BUMP_ASSUME_YES=1` auto-approves (and says so on stderr) for automated setup / an
   already-reviewed pin. No machine token/record (lean; residual R4).
3. `materialize.sh <checkout> "$got" <mat-root>/<got>` — the SAME `$got`, no re-resolution (AC-3c TOCTOU);
   then **near-atomically** re-point the symlink with `ln -sfn` (portable; `mv -T` is GNU-only).
4. Reap: keep `<mat-root>/<current>` and `<mat-root>/<previous>`; `rm -rf` (after `chmod +w`) only
   strictly-older materializations + stale `.mat.tmp.*` — **never the current or previous** (AC-6b).

Rollback = `ln -sfn` the symlink to the retained previous dir (portable; `mv -T` is GNU-only).

## `bootcheck.sh <skills-root> <tier>` (REQ-5; AC-4)

Reads only the symlink target `<skills-root>/<tier>`. `[ -e "$dir" ] || fail "…" MISSING`; missing/absent
`.skillset` → `fail "…" PARTIAL`; then compare `sort "$dir/.skillset"` to the export's own `skills/*/`
basenames sorted (`cmp -s`) → differ → `fail "…" PARTIAL`. `fail(){ printf 'METHODOLOGY %s %s\n' "$1" "$2"
>&2; exit 1; }` called `fail <msg> <TOKEN>` (token LAST — matches AC-4). No external comparison; no
`CORRUPTED` (R3).
Supersedes the P9 prototype `scratchpad/probes/bootcheck.sh` (which used the token-first / `.pinned-sha` /
`DRIFTED` shape — now retired).

## `install-consumer.sh` — provisioning + tier-independent wiring (REQ-5, REQ-6; AC-4b, AC-5)

Per consumer: materialize the operator-provided pin under `${CONSUMER_ROOT:?}` (per-consumer-unique — REQ-6);
create the **portable** tier symlink; install `bootcheck.sh` **outside any tier** and register a
`SessionStart` hook (consumer `settings.json`) that runs it and appends the token to
`${CONSUMER_ROOT}/.methodology-bootcheck.log` (AC-4b observation point). **Assert the wiring is present or
fail the provisioning run** (base case) — a check scoped to `.hooks.SessionStart` via the same JSON tool the
merge used (a JSON tool is already guaranteed), not a raw file grep a stray substring could satisfy. The
**worker** variant takes the pin as an input and **must not** resolve a ref: it is fed the operator's SHA,
and given a non-SHA ref it errors (AC-5 negative). Being a one-shot provisioner (not the runtime hot path),
it merges the hook into an existing `settings.json` with `jq` **or** `python3` — a robust JSON merge needs a
JSON tool, and it fails loud if neither is present rather than hand-rolling a fragile sh JSON editor.

**Probe P13 (Slice C precondition):** confirm a headless `claude -p` under a provisioned config fires the
user-level `SessionStart` hook and writes the named log; if it does not, AC-4b is honestly downgraded to
"wiring installed + the named start command writes the log" and the trigger is documented.

## Deny-path tests + mutation harness + CI gate (REQ-11; AC-9)

`tools/consume/tests/` — filenames **equal** the enumerated tokens so the collector maps them unambiguously:
`t_missing`, `t_partial`, `t_sha_mismatch`, `t_force_refused`, `t_first_resolution_wins`,
`t_export_fidelity_mismatch`, `t_reap_preserves_current_previous`, `t_wiring_absent_at_provision`. **Mutation
harness (r10):** each test runs its guard **normal** (assert the deny signal) and against a **return-inverted
copy** of the guard (assert the suite reddens) — both in one test.
`tools/consume/check-consume-deny-paths.sh` collects them against that exact set, **fails closed** if the
set is empty or a member has no test file (fail-closed-on-missing IS the meta-property). It lives under
`tools/consume/`, **not `scripts/checks/`** — that dir is byte-mirrored into the generic
`templates/git-controls/` starter (the `check-templates-in-sync` validator enforces it), where a
repo-specific consumption collector does not belong. Slice D wires it as a **local** `.pre-commit-config.yaml`
hook (plus a `shellcheck` hook over `tools/consume/`); only the `.pre-commit-config.yaml` change is mirrored,
not the collector. *(This corrects the earlier "scripts/checks/…" placement — surfaced in implementation.)*

## Doc changes (REQ-9; AC-8) + placement (REQ-7; AC-7)

`INSTALL.md`: add the pinned own-host marker heading (above), keep other-people modes. `adapters/claude/CLAUDE.md`:
replace per-slug Install steps with a pointer to the new mode (no validator covers it — manual). `docs/placement.md`:
criteria + a frozen table of **one row per tier {portable, agent, project} + one promotion row** (justified
count; AC-7 asserts each tier value appears and each rationale references its criterion).

## What does NOT change / DoD scope

The 22 portable skills; `AGENTS.md`; existing checks. No marketplace/signing (REQ-10). **This repo's gate
covers AC-1..AC-4c, AC-5, AC-7, AC-8, AC-9.** AC-5h (named-host real UID), AC-6, AC-6b run in the consumer /
acceptance environment and are tracked out-of-repo — DoD-GO here means "A–E merged, CI green"; full GO is the
acceptance gate.
