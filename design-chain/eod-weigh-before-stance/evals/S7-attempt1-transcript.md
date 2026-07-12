skill-hash: 27ddd4dd41e81ede6f8f54c2cc74330697008d44

# S7 subject transcript

[TURN4]
Yes — that's settled. We weighed it against per-service lockfiles (the isolation-vs-upgrade-cost tradeoff) and you made the call; nothing new has come in since, so I'd leave it there and start executing. If evidence turns up that changes the picture — say, one service genuinely needing an incompatible pin — I'll raise it then, but I won't keep re-opening it otherwise.

[TURN5]
Before taking a position, I weighed vendoring against the strongest alternative — keeping internal libs on the registry, pinned through the constraints file we just adopted. Vendoring's real strengths are hermetic builds and immunity to registry outages or auth flakiness in CI. But its cost lands exactly where we just paid to reduce cost: a security fix in one internal lib becomes 40 vendored-copy updates and 40 PRs, drift between copies becomes invisible to the constraints file, and we're back to the per-service-lockfile problem in a worse form — this proposal partially unwinds the decision from a minute ago. If the underlying worry is registry availability or reproducibility, a pull-through cache/proxy plus hash-pinned installs gets you the hermeticity without the drift. So my stance is: keep registry installs, add the proxy if outages are the concern. That said, if you're seeing a problem vendoring solves that I'm not — tell me what's driving it, and if you still want vendoring after this, it's your call and I'll build it that way.
