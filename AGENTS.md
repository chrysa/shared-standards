<!-- chrysa:standards-agents:start · generated · DO NOT EDIT -->
# chrysa standards — summary (generated)

> Always-on summary of the canon `standards/STANDARDS.chrysa.md`. Every canon rule applies, not only these. Full rule index: the `chrysa:standards` block of `CLAUDE.md`. Detail, on demand: the `chrysa-standards` skill, or `standards/rules/<domain>.md`.

Non-negotiable (domain in backticks):
- Cross-cutting stack (settled ADRs — do not relitigate) · `stack`
- Language: English — all code, comments, docs, instructions, and config files. · `governance`
- Commits: Conventional Commits (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`). · `scm`
- Branch model — `main` is production, `develop` is the workspace · `scm`
- Tests: pytest only · `testing`
- Agent actions are governed · `agents`
- An agent writes only where the owner owns · `agents`
- Security scanning is a gate, not an afterthought — it runs in pre-commit and in CI · `security`
- Everything runs in a container — the only exception is the slice of a repo genuinely bound to the host OS · `containers`
- External dependencies are installed in containers, never on the host · `containers`
- Pre-commit & git hooks (native, via pre-commit.com — never wrapped in make) · `ci-cd`
- Governance — strategic pillars & ADR format · `governance`

Domains: `standards/rules/{governance,stack,scm,architecture,testing,frontend,api,accessibility,docs,agents,security,code-quality,product,backend-python,data,observability,containers,design,dev-loop,ci-cd,ai-orchestration}.md`
<!-- chrysa:standards-agents:end -->
