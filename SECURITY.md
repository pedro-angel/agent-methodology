# Security Policy

## Scope

This project is a **documentation-and-shell-script methodology pack**. It ships:

- Markdown (`AGENTS.md`, `README.md`, `INSTALL.md`, `skills/**`, `adapters/**`)
- Zero-dependency POSIX `sh` validators (`scripts/checks/**`)
- CI / pre-commit configuration (`.github/**`, `.pre-commit-config.yaml`)

There is **no runtime, no server, no network access, and no third-party code is
vendored or redistributed** — the dev-time hooks (pre-commit, markdownlint) are
installed from their own upstreams, not bundled here. The realistic attack
surface is therefore a validator that can be tricked into passing when it should
fail, or a script that behaves unexpectedly when copied into a consuming repo.

## Reporting a vulnerability

Please report suspected security issues **privately**, not in a public issue:

- Preferred: GitHub's **private vulnerability reporting** — the *Security* tab →
  *Report a vulnerability* (enable it under *Settings → Security → Private
  vulnerability reporting* before first use).

This is a solo, best-effort project; expect an acknowledgement within a couple of
weeks. If a check can be bypassed or a script can be coerced into a false pass,
that is in scope — include the exact input and the expected vs. actual result.

## Supported versions

The latest commit on `main` (and the most recent tag, once tags exist) is the
only supported version. There are no backports.
