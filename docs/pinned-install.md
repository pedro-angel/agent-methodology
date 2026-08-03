# Pinned install, step by step — any host, any user

This walkthrough takes one user on one machine from nothing to the full methodology in pinned
mode: an immutable, reviewed export of one commit serving every project, always-on communication
rules, a boot check on every session, and a one-command update path. Run every block as the user
being provisioned. Nothing here touches any other user.

What you end up with:

| Artifact | Path | Job |
| --- | --- | --- |
| The tier symlink | `~/.claude/skills/agent-methodology` | one link → the pinned, read-only export; serves every project |
| The consumer store | `~/.methodology-consumer/` | materializations, the boot check, its log, your `bump` command |
| Always-on rules | `~/.claude/CLAUDE.md` | the every-turn rules, loaded into every session |
| A SessionStart hook | in `~/.claude/settings.json` | runs the boot check at each session start |

## Step 1 — prerequisites

```sh
command -v git && command -v claude && { command -v jq || command -v python3; } \
  && echo READY || echo MISSING-TOOLS
```

`git` and the `claude` CLI are required everywhere; `jq` *or* `python3` is needed once, for the
provisioning step's settings merge. If `READY` doesn't print, install what's missing first.

The user must also be **signed in to Claude** (run `claude` once interactively and log in) — the
Step 7 session checks need a working session, though the install itself does not.

## Step 2 — get the pack and choose the pin

```sh
git clone https://github.com/pedro-angel/agent-methodology ~/agent-methodology
PACK=~/agent-methodology
SHA=$(git -C "$PACK" rev-parse origin/main)     # or a specific reviewed commit / tag
echo "pinning: $SHA"
```

The pin is the whole point of this mode: what your agent consumes is this exact commit, read-only,
until you deliberately move it. Review the commit you pin (`git -C "$PACK" log -1 $SHA`) — the
operator's act of choosing it *is* the approval.

## Step 3 — decide exclusions (skip if none apply)

If another installed plugin already owns some of the pack's skills — for example
extended-superpowers ships its own environment-research, adversarial-review, acceptance-tests, and
definition-of-done — exclude the pack's versions, or the near-duplicate names make skill routing
nondeterministic:

```sh
EXCLUDES="acceptance-tests-observable-outcomes adversarial-lens-review definition-of-done-tooling environment-research"
```

No overlapping plugins? Set `EXCLUDES=""`. A typo here fails loudly at the next step rather than
silently shipping the skill it meant to exclude.

## Step 4 — provision

```sh
MAT_EXCLUDE_SKILLS="$EXCLUDES" \
sh "$PACK/tools/consume/install-consumer.sh" "$PACK" "$SHA" "$HOME/.methodology-consumer" "$HOME/.claude"
```

The four arguments, in order: the pack checkout, the approved pin, a consumer root unique to this
user, and this user's Claude config dir. On success it prints one `install-consumer: OK` line. It
materializes the pin into a read-only export, links it as the tier, installs the boot check
*outside* the tier (so a broken tier can't silence its own alarm), and registers the SessionStart
hook — refusing loudly rather than proceeding if any wiring step fails.

## Step 5 — always-on rules

Skills load per task; the reader-first communication rules must load every turn, so they live in
the user memory file. This is idempotent — safe to re-run after a bump:

```sh
TIER=$(readlink "$HOME/.claude/skills/agent-methodology")
grep -q 'Every-turn rules' "$HOME/.claude/CLAUDE.md" 2>/dev/null \
  || sed -n '/^## Every-turn rules/,/^## The principles/p' "$TIER/AGENTS.md" | sed '$d' >> "$HOME/.claude/CLAUDE.md"
```

Already have a `~/.claude/CLAUDE.md`? The rules append after your content; user memory is additive.

## Step 6 — install your `bump` command

Updates must never depend on remembering the exclusion list — bake it in once:

```sh
cat > "$HOME/.methodology-consumer/bump" <<EOF
#!/bin/sh
# bump <ref-or-sha> — THE way to update the methodology for this user.
set -eu
PACK=$PACK
CROOT=\$HOME/.methodology-consumer
[ \$# -eq 1 ] || { echo "usage: bump <ref-or-sha>" >&2; exit 1; }
git -C "\$PACK" fetch origin >/dev/null 2>&1 || true
sha=\$(git -C "\$PACK" rev-parse --verify "\${1}^{commit}")
MAT_EXCLUDE_SKILLS="$EXCLUDES" \\
  sh "\$PACK/tools/consume/bump.sh" "\$PACK" "\$sha" "\$sha" "\$CROOT/mat" "\$HOME/.claude/skills/agent-methodology"
tail -1 "\$CROOT/.methodology-bootcheck.log" 2>/dev/null || true
EOF
chmod +x "$HOME/.methodology-consumer/bump"
```

## Step 7 — verify it took

Three checks, each with its expected shape:

```sh
# 1. the tier resolves, read-only, with the expected skill count
wc -l "$(readlink "$HOME/.claude/skills/agent-methodology")/.skillset"     # 22 minus your exclusions

# 2. a real session fires the boot check
claude -p "reply with exactly: ok" >/dev/null 2>&1 || true
tail -1 "$HOME/.methodology-consumer/.methodology-bootcheck.log"           # METHODOLOGY OK — tier agent-methodology, N skill(s)

# 3. the rules reach a fresh session
claude -p "Do not use tools. Does your context contain a section titled 'Every-turn rules'? Answer INHERITED or NOT PRESENT."
```

If any check misses, stop and fix before relying on the install — the boot-check log's `MISSING`
or `PARTIAL` token names the fault.

## Updating and rolling back

```sh
"$HOME/.methodology-consumer/bump" origin/main    # shows the executable-content diff for review
```

A bump keeps the previous materialization; rolling back is re-pointing one symlink at it:

```sh
ls "$HOME/.methodology-consumer/mat/"                                      # current + previous
ln -sfn "$HOME/.methodology-consumer/mat/<previous-sha>" "$HOME/.claude/skills/agent-methodology"
```

After a bump, re-run Step 5 if the every-turn rules changed upstream (the guard makes re-running
free), and re-run the Step 7 checks.

## Uninstalling

```sh
rm "$HOME/.claude/skills/agent-methodology"
rm -rf "$HOME/.methodology-consumer"
```

Then delete the boot-check entry from `hooks.SessionStart` in `~/.claude/settings.json`, and remove
the every-turn section from `~/.claude/CLAUDE.md` if you no longer want the rules. The pack clone
at `$PACK` is yours to keep or delete.

## Migrating an existing non-pinned install

Coming from vendored copies or per-slug symlinks? That's a cutover, not a fresh install — follow
the [cutover runbook](cutover-runbook.md), which adds the fallback record, the ordered log, and the
rollback drill.
