# Contributing

Thanks for your interest. This is a small, opinionated methodology pack; the bar
for changes is that they make the guidance more portable, more honest, or more
machine-enforced — and that they pass the same checks the pack preaches.

By submitting a contribution you agree it is licensed under the repository's
[MIT License](LICENSE) (inbound = outbound), and you certify the
[Developer Certificate of Origin](https://developercertificate.org/) by signing
off your commits (`git commit -s`).

## What lives where

- **`AGENTS.md`** is the single source of truth (the principles + index).
- **`skills/<slug>/SKILL.md`** carries the detail: rules, red-flags, worked examples.
- **`adapters/**`** are per-agent entry points. The Claude and Gemini adapters are
  thin pointers; the Cursor and Copilot adapters inline a *condensed index* because
  those tools don't reliably follow a pointer. **That inlined index is derived from
  `AGENTS.md` — if you change the skill set, update every adapter to match** (CI
  enforces that each adapter enumerates all skills).

Edit `AGENTS.md` and the `SKILL.md` files; keep adapters in sync. Never copy the
full rule text into an adapter.

## Local setup

```bash
pip install pre-commit            # or: pipx install pre-commit
pre-commit install --install-hooks
```

Run every check exactly as CI does:

```bash
pre-commit run --all-files
```

CI re-runs this *same* `.pre-commit-config.yaml`, so a green local run is a green CI.

## Commit conventions (CI-enforced)

Every commit message must satisfy two machine checks:

1. **A [Conventional Commits](https://www.conventionalcommits.org/) type prefix** —
   one of `feat, fix, docs, chore, refactor, test, build, ci, perf, style, revert`.
2. **A provenance trailer** — at least one of `Signed-off-by:`, `Co-Authored-By:`,
   `Evidence:`, `Refs:`, or `Verified-by:`.

The easiest way to satisfy the trailer requirement *and* the DCO is to sign off:

```bash
git commit -s -m "docs: clarify the adapter sync rule"
```

That adds `Signed-off-by: Your Name <you@example.com>`, which passes both gates.

## Style

Keep the change surgical (see [`skills/surgical-changes-with-checkpoints`](skills/surgical-changes-with-checkpoints/SKILL.md)):
one motivation per commit, match the surrounding prose voice, and treat the docs as
the deliverable. Every factual claim you add should be true against the repo as it
actually is.
