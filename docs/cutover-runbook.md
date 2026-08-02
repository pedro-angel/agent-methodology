# Cutover runbook — legacy install → pinned plugin

This runbook migrates one consumer from a legacy install of the pack to the
[Tag-pinned plugin](../INSTALL.md#tag-pinned-plugin-audited-immutable-consumption) mode: a single
symlink to a read-only, SHA-pinned materialization, boot-checked on every session start.

Two legacy shapes exist, and both migrate with the same phases:

- **Per-slug symlinks** — `~/.claude/skills/<slug>` links pointing into a live working tree
  (the retired install mode; agents consume unreviewed, mid-edit state).
- **Vendored copies** — real `AGENTS.md` + `skills/` files committed into a consuming repo.
  Their teardown is a reviewed PR in that repo, not shell commands on a host.

## The ordered-log contract

Every phase appends one line — `<PHASE> <UTC-timestamp> <detail>` — to a `cutover.log` kept
beside the consumer root. The phases MUST appear in this order, and a later phase must never
precede an earlier one in the log:

```text
TEARDOWN ≺ STANDUP ≺ BOOTCHECK_GREEN ≺ REMOVE_FALLBACK
```

Teardown runs first so there is never a window where the same skill is loaded twice (bare
via the legacy path and namespaced via the plugin). The gap this opens is seconds long, and
`BOOTCHECK_GREEN` before `REMOVE_FALLBACK` guarantees rollback stays one command until the
new mode is verified.

## Phase 0 — record the fallback (before touching anything)

Capture the exact legacy state so rollback is mechanical, not archaeological:

```sh
CROOT=$HOME/.methodology-consumer          # per-consumer-unique root (REQ-6)
mkdir -p "$CROOT"
ls -la ~/.claude/skills > "$CROOT/cutover-fallback.txt"
```

For a vendored-copy consumer: the fallback is the pre-cutover git ref — record the SHA.

## Phase 1 — TEARDOWN

Remove only the legacy links that point into the pack — never unrelated entries:

```sh
PACK=/path/to/agent-methodology            # the checkout the legacy links point into
for l in ~/.claude/skills/*; do
  [ -L "$l" ] || continue
  case "$(readlink "$l")" in
    "$PACK"/*) rm "$l"; printf 'removed %s\n' "$l" ;;
  esac
done
printf 'TEARDOWN %s legacy per-slug symlinks into %s\n' "$(date -u +%FT%TZ)" "$PACK" >> "$CROOT/cutover.log"
```

Vendored-copy consumers: open the de-vendoring PR (`git rm` the vendored files) instead;
its merge is this phase's log line.

## Phase 2 — STANDUP

Pin a reviewed SHA — never a live working tree — and provision:

```sh
SHA=$(git -C "$PACK" rev-parse origin/main)   # or the specific reviewed commit
MAT_EXCLUDE_SKILLS="" \
sh "$PACK/tools/consume/install-consumer.sh" "$PACK" "$SHA" "$CROOT" "$HOME/.claude"
printf 'STANDUP %s pinned @ %s\n' "$(date -u +%FT%TZ)" "$SHA" >> "$CROOT/cutover.log"
```

Set `MAT_EXCLUDE_SKILLS` to the slugs another installed plugin already owns (see
`materialize.sh`); leave it empty to ship the full tier.

## Phase 3 — BOOTCHECK_GREEN

Prove it with a real session, not by reading the scripts:

```sh
claude -p "reply with exactly: ok" >/dev/null 2>&1 || true   # any session fires the hook
tail -1 "$CROOT/.methodology-bootcheck.log"                   # want: METHODOLOGY OK — tier agent-methodology, N skill(s)
claude plugin details agent-methodology | head -20            # want: every non-excluded skill listed
printf 'BOOTCHECK_GREEN %s %s\n' "$(date -u +%FT%TZ)" "$(tail -1 "$CROOT/.methodology-bootcheck.log")" >> "$CROOT/cutover.log"
```

If the boot check is not green, STOP — roll back (below) and diagnose. Do not proceed.

## Rollback drill — run it once before trusting the cutover

A rollback that has never been executed is a hope, not a capability. After the first
`BOOTCHECK_GREEN`, actually roll back, verify, and cut over again:

```sh
# roll back: remove the plugin symlink, recreate the legacy links from the fallback record
rm ~/.claude/skills/agent-methodology
awk '/->/ { print $(NF-2), $NF }' "$CROOT/cutover-fallback.txt" | while read -r name target; do
  ln -s "$target" ~/.claude/skills/"$name"
done
ls ~/.claude/skills | head -3                                  # legacy state restored
# then redo Phases 1–3; both drills append to cutover.log
```

For a bump gone wrong later (not a cutover), rollback is simpler: `ln -sfn` the tier
symlink back to the retained previous materialization.

## Phase 4 — REMOVE_FALLBACK

Only after a soak the operator chooses (days, not minutes), remove the fallback record —
until this line is logged, rollback stays one command:

```sh
rm "$CROOT/cutover-fallback.txt"
printf 'REMOVE_FALLBACK %s\n' "$(date -u +%FT%TZ)" >> "$CROOT/cutover.log"
```

Vendored-copy consumers: this is deleting the pre-cutover branch/tag kept as fallback.

## Verification of the log contract

The log itself is checkable — phases present, ordered, timestamps monotonic:

```sh
awk '{print $1}' "$CROOT/cutover.log" | grep -E '^(TEARDOWN|STANDUP|BOOTCHECK_GREEN|REMOVE_FALLBACK)$' \
  | awk 'BEGIN{o["TEARDOWN"]=1;o["STANDUP"]=2;o["BOOTCHECK_GREEN"]=3;o["REMOVE_FALLBACK"]=4}
         {if (o[$1] < last) {print "ORDER VIOLATION at " $1; exit 1}; last=o[$1]} END{print "order ok"}'
```
