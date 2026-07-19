# Placement — which tier a lesson or skill belongs in

The pack ships in tiers. When a lesson earns a place in the methodology, decide *which* tier it
belongs to by the criteria below, then let it flow **upward** if it later proves more general than
where it started. The rule of thumb: write a lesson at the **most general tier its content actually
supports** — no lower (it would be re-learned elsewhere), no higher (it would mislead agents it does
not apply to).

## Portable tier

**Criterion: the lesson is agent-agnostic** — general engineering discipline that holds for *any* AI
coding agent (or a human), independent of one tool's runtime or features. If you can state it without
naming a specific agent's mechanics, it is portable. These live in `skills/` + `AGENTS.md` and every
adapter surfaces them.

## Agent tier

**Criterion: the lesson depends on a specific agent's runtime or features** — a mechanic that only
makes sense for that agent (a hook lifecycle, a plugin/skill loader, a slash-command surface). It is
true and useful, but only *for that agent*, so it must not be stated as a portable rule. These live in
the agent-specific tier (for Claude Code, the `agent-methodology-claude` plugin tier).

## Project tier

**Criterion: the lesson is specific to this repo's own structure or deployment** — how *this* project
is built, provisioned, or wired, not a reusable principle. It stays a project artifact (an ADR or doc
in the consuming repo), never a portable skill, because it would not transfer to another codebase.

## Upward promotion

**Criterion: promote a lesson when it generalizes** — a project- or agent-tier lesson that turns out
to hold more broadly gets **generalized and moved up** toward portable (agent-specific detail stripped
out). Promotion is one-directional: content flows up as it proves general, never down. When you
promote, rewrite it at the higher tier's altitude, don't just copy it.

## Frozen examples

Labeled lessons from this pack's own history, one per tier plus a promotion. Each row's rationale
names the criterion of its tier.

| Lesson | Tier | Rationale |
| ------ | ---- | --------- |
| Test the deny path and mutation-verify the fail-closed return before trusting a gate | portable | Agent-agnostic engineering discipline — a gate's correctness holds for any agent or human, so it belongs at the most general tier. |
| A `SessionStart` hook carries phase-ordering precedence that a skill description alone cannot | agent | Depends on Claude Code's specific hook runtime — true only for that agent's features, so it stays in the agent tier, not stated as portable. |
| Each consumer provisions its own per-host materialization root under `${CONSUMER_ROOT}` | project | Specific to how this pack is deployed to its own hosts — a deployment detail of this repo, not a reusable principle, so it stays a project artifact. |
| Error-swallowing on a gate — hiding a command's failure and forcing a zero exit — is a silent fail-open | portable | Began as a single project bug, then generalized: the failure mode is agent-agnostic, so it was promoted upward and rewritten as a portable gate-discipline rule. |
