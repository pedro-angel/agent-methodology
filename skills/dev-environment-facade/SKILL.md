---
name: dev-environment-facade
description: Use when wiring a project's dev workflow (local stack, test tiers, gates, docs) — build a thin self-documenting Makefile facade over real scripts, and split env files by owner so targets consume them but never write them.
---

# One Entry Point, Zero Ownership Confusion

A project's dev workflow deserves one discoverable surface: a thin facade
(`make help` tells the whole story) that delegates to real scripts and tools,
plus environment files whose ownership is so clear that no target ever needs
to rewrite what a human maintains. The facade encodes *which tool with which
flags*; procedures live in scripts; generated and hand-edited configuration
never share a file.

## When to use

Reach for this skill when adding a task runner or Makefile, when designing how
tests obtain credentials from a local stack, or when a "just run this one
command" developer experience is the goal.

Red-flag thoughts — if you catch yourself thinking any of these, STOP:

- "I'll put the logic in the Makefile." (Recipes are one-liners; logic lives in scripts.)
- "The test target can regenerate the env file while it's at it." (Targets consume; provisioning writes.)
- "I'll preserve the user's lines while rewriting the file." (Preservation machinery means the ownership split is missing.)
- "The recipe can just `source` the env file." (Shell-sourcing hand-edited files couples correctness to shell syntax; load in-process.)
- "The suite skipped, and skipped is green." (A certifying gate that passes on zero executed tests is a hole.)
- "Any 200 from the service proves the credential works." (Probe the endpoint — some are auth-blind.)

## The rule

1. **Delegate, never duplicate.** Every recipe is a one-liner invoking a
   script or a tool; multi-step procedures live in `scripts/`. The facade is
   self-documenting: `.DEFAULT_GOAL := help`, every target annotated with a
   `## description`, help rendered by a grep/awk over `$(MAKEFILE_LIST)` —
   and the grep's character class must include digits, or a target like
   `e2e` silently vanishes from the help.
2. **Mirror gate commands character-identically, and check the mirror.**
   Where the facade and a certifying gate run the same command, the strings
   must be byte-identical in both files, enforced by a `grep -F` loop —
   drift between "what developers run" and "what certifies done" is silent
   otherwise.
3. **Split env files by owner.** Machine-generated values (URLs, minted
   credentials) live in a file only the provisioning script writes — atomic
   temp-plus-rename, and *conditional*: keep a still-valid credential rather
   than minting on every run, validating against an endpoint that actually
   discriminates (probe it: some status endpoints return 200 to a bogus
   key). User-owned values live in a separate file no script ever writes or
   deletes. If the machine file contains foreign lines, abort with
   instructions — never silently drop them.
4. **Consumers load env in-process, at the last responsible moment.** Test
   suites read the env files themselves (a small loader in the test tree),
   at fixture time — never at conftest import, because test runners import
   deselected suites' conftests during collection, and a broken stack state
   must not brick unrelated runs. Merge with explicit-environment-wins
   semantics (`setdefault`), and *warn* when a shell export shadows a
   differing file value — a silent precedence inversion aims mutating suites
   at the wrong system.
5. **Absent and broken are different states.** No machine env file → skip
   the dependent suites ("no stack claimed"). File present but a required
   key missing, empty, or shadowed empty → fail hard with a
   cause-distinguishing message. A present file claims a working stack;
   silence on a broken claim is how gates go green on zero tests.
6. **Destructive verbs never touch user-owned files**, and the destructive
   target's own `## help` line carries the warning about what it does
   delete.

## Why

Each half protects the other. A facade without the ownership split ends up
rewriting mixed files with preserve-the-user's-lines machinery — rewrite
races, "teardown ate my config," and migration dances follow. An ownership
split without the facade leaves the knowledge of which script writes what in
people's heads. And both fail quietly without the gate rules: mirrored
commands drift, skipped suites read as green, and the first sign is a release
certified by a gate that ran nothing. The costs arrive late and misattributed
— a developer whose stray shell export silently redirects a mutating test
suite at a real system will debug everything except their own environment.

## In practice

Three field builds shaped this skill. The first (a Python client library)
established the facade: twenty one-line targets over `local-stack.sh` and
venv binaries, a self-documenting help, and integration tests that read the
stack's generated `.env`/`.env.local` themselves — make consumed, never
wrote. The second (an MCP server) ported the facade onto a uv/pytest repo and
added the mirror discipline: nine command strings byte-identical between the
Makefile and a Definition-of-Done gate, grep-verified in acceptance; its
probes also caught that the obvious credential-validity endpoint
(`/api/status`) returns 200 to a bogus API key — the conditional mint would
have kept dead keys forever, and only probing found the discriminating
endpoint. The third build split that repo's mixed env file by owner, and two
review findings became rules here: an import-time loader was reproduced
bricking plain unit runs (collection imports deselected conftests — rule 4's
"fixture time" is not a style preference), and the switch from shell-sourcing
to `setdefault` silently *inverted* precedence for anyone with a stray
`KIBANA_URL` export — hence rule 4's shadow warning.

## Anti-patterns

- Logic in recipes — a Makefile that is itself a program.
- A test or gate target that writes, rewrites, or deletes an env file.
- Preserve-user-lines rewrite machinery instead of an ownership split.
- Shell-sourcing hand-edited env files inside recipes or gate scripts.
- Loading env at conftest import time ("it's only for the contract suite" —
  collection imports it everywhere).
- Validating a credential against an endpoint you never probed for
  auth-blindness.
- Skip-on-broken-state: treating a present-but-keyless env file the same as
  no file at all.
- A help grep whose character class silently hides targets with digits.

## Enforcement

What a machine can check: bare `make` exits 0 and its (ANSI-stripped) output
lists every target, diffed against an enumerated list; a `grep -F` loop over
the mirrored command strings passes against both the Makefile and the gate
script; a grep proves no recipe or gate line writes the env files (the
provisioning script is the only writer); the certifying gate's suite runs
assert `passed ≥ 1` and `skipped = 0` in their logs; and the broken-state
path is provoked in acceptance — env file present but keyless must yield a
hard failure, file absent must yield the skip.

## Related skills

- [../configuration-single-source-of-truth/SKILL.md](../configuration-single-source-of-truth/SKILL.md)
- [../grounded-verifiable-gates/SKILL.md](../grounded-verifiable-gates/SKILL.md)
- [../battle-testing-on-real-infra/SKILL.md](../battle-testing-on-real-infra/SKILL.md)
- [../environment-research/SKILL.md](../environment-research/SKILL.md)
- [../secrets-and-teardown-discipline/SKILL.md](../secrets-and-teardown-discipline/SKILL.md)
- [../reversible-by-default-confirm-consequential/SKILL.md](../reversible-by-default-confirm-consequential/SKILL.md)
