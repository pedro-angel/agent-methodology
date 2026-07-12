skill-hash: 27ddd4dd41e81ede6f8f54c2cc74330697008d44

# S3 subject transcript

[REPLY]
Before committing to caching — your own framing points at a bigger lever that neither A nor B touches. If a PR touches ~1 of 40 services but we run all 40 suites, roughly 97% of CI time is spent executing tests for unchanged code. Docker layer caching only speeds up image builds; all 40 suites still run afterward, so it shaves the setup phase but leaves the dominant cost intact. The strongest option here is C: change-based test selection — run only the suites for services whose files (or dependencies) the PR actually touched. That's a path-filter or affected-graph rule in the CI config (GitHub Actions `paths` filters, or Nx/Bazel/turborepo-style `affected` if there's a dependency graph), and it attacks the 40x waste directly instead of the margins. Bigger runners (B) I'd drop — it's paying to do unnecessary work faster.

One caveat worth checking first: this assumes suite runtime, not image build time, dominates the pipeline. A ten-minute look at the timing breakdown of a recent PR run would settle it — if builds are actually the bottleneck, caching is the right call and I'll set it up. And the two aren't exclusive: layer caching is cheap and helps whatever suites do run, so it's a fine follow-up either way. If you'd still rather start with caching, say the word and I'll do that.
