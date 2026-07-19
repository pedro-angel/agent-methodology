# Experiment log — consumer provisioning (Slice C), 2026-07-19

*Method: `environment-research` — real runs against the actual runtime, outputs captured verbatim so a
reviewer checks this instead of re-running. Runtime: **Claude Code `claude` 2.1.211 on aarch64 Linux
(dash `/bin/sh`)** — a genuinely different target from the macOS host the earlier probes used, so the same
scripts are now exercised under a strict-POSIX shell and GNU coreutils/tar. Every session ran under an
**isolated** `CLAUDE_CONFIG_DIR` (a scratch dir holding only a copied credential + a `settings.json`), so
the host's real config was never touched. Scratch trees were removed afterward (0 residue).*

## P13 — does a headless `claude -p` fire a user-level SessionStart hook?

This is the load-bearing assumption behind the boot check: a hook registered in the consumer's
`settings.json` must run on **every** session, including the headless workers, or the check is dead weight.

Setup: an isolated config with a single `SessionStart` hook whose command writes a marker file, then one
`claude -p "reply with exactly: ok"`.

```text
== headless claude -p under CLAUDE_CONFIG_DIR=/tmp/tmp.XXXX/cfg ==
claude -p exit=0; output(1st line)=[ok]; stderr(tail)=[]
RESULT: P13 = SessionStart hook FIRED in headless -p (marker written)
```

**Result: CONFIRMED.** A user-level `SessionStart` hook fires under headless `-p`. The boot check can rely
on it — no manual invocation, no interactive-only gap. AC-4b holds with no downgrade.

*(Version note: SPECS pins CLI-dependent ACs to `claude` 2.1.214; this aarch64 host runs 2.1.211, three
patches back. The observation here is the `SessionStart`-fires-headless hook mechanism, not a version-gated
feature, so the patch skew does not weaken it. The earlier probe run on 2.1.214 covers the version-pinned
discovery ACs.)*

## Live provisioning — `install-consumer.sh` end to end, then the hook actually runs the check

Setup: a scratch pack (2 skills), `install-consumer.sh <pack> <sha> <croot> <cfg>` into an isolated config,
then a `claude -p` on the healthy tier and again with the tier symlink deliberately dangled.

```text
== provision ==
bump: OK — .../cfg/skills/agent-methodology -> .../croot/mat/49b71ad… @ 49b71ad… (previous kept: none)
install-consumer: OK — agent-methodology pinned @ 49b71ad… + boot check wired (log: .../.methodology-bootcheck.log)
-- SessionStart hook:
[{"hooks":[{"type":"command","command":"'.../croot/bootcheck.sh' '.../cfg/skills' agent-methodology >> '.../.methodology-bootcheck.log' 2>&1 || true"}]}]

== healthy tier: run claude -p ==
session rc=1; log => [METHODOLOGY OK — tier agent-methodology, 2 skill(s)]

== broken tier (dangling symlink): ==
session rc=1; output=[Failed to authenticate: OAuth session expired and could not be refreshed]
log => [METHODOLOGY tier 'agent-methodology' does not resolve MISSING]
```

**Result: CONFIRMED (with one honest caveat).** Provisioning wires the tier symlink + a `SessionStart` hook
that invokes the out-of-tier boot check; on session start the hook runs and writes the correct line to the
named log — `OK … 2 skill(s)` on a healthy tier, `… does not resolve MISSING` on a dangled one.

Caveat: `session rc=1` here is **not** a provisioning defect. A copied credential is a static OAuth token
that cannot refresh the way the live deployment does; between P13 and this run it expired, so the API call
failed. The `SessionStart` hook fires *before* that API call, which is exactly why both log lines were still
written correctly. The observable Slice C claims — the hook auto-runs the check and records the result
without manual invocation — is met; a green interactive session is a claude-auth matter, not this script's.

Residual (carried, not blocking): the hook redirects into the named log (`2>&1`) and ends `|| true`, so a
fault is recorded but not surfaced *in* the session. Whether a non-zero `SessionStart` is shown in-session
(vs. blocking it) could not be tested here because auth failed; the named log is the confirmed observable.
