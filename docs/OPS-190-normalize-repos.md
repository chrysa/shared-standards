# OPS-190: Normalize Quality Gate Setup Across All Active Repos

## Overview
This task ensures all development repositories have consistent quality gate setup (scripts, configs, workflows, Make targets) enabling regression prevention before code merges.

## Current Status (Audit Results)

| Status | Count | Action |
|--------|-------|--------|
| ✅ Complete | 2 | None (padam-av, padam-av-backoffice) |
| ⚠️ Partial | 32 | Apply normalization script |
| ❌ Missing | 14 | Not applicable (archived/non-dev repos) |
| **Total Scanned** | **48** | — |

## Deployment Strategy

### Phase 1: Key Repos (Week 1)
Apply normalization to highest-impact repos first:

```bash
./scripts/batch-normalize-quality-gate.sh \
  --repos=lifeos,server,coach,mediavault,chrysa-lib,container-webview
```

**Target repos:**
- `lifeos` — Core platform library
- `server` — Main backend service
- `coach` — Assistant service
- `mediavault` — Media management
- `chrysa-lib` — Shared utilities
- `container-webview` — Web UI service

### Phase 2: Secondary Repos (Week 2)
```bash
./scripts/batch-normalize-quality-gate.sh \
  --repos=dev-nexus,ai-aggregator,discord-bot-back,diy-stream-deck,notion-automation,project-init
```

### Phase 3: Remaining (Week 3)
```bash
# All partial repos not covered in Phase 1-2
./scripts/batch-normalize-quality-gate.sh --repos=agent-config,automations,doc-gen,epub-sorter,floating-agent
```

## Automation Scripts

### 1. Audit Script
**Location:** `shared-standards/scripts/audit-quality-gate-repos.sh`

Scans all repos, identifies setup status:
```bash
./scripts/audit-quality-gate-repos.sh
# Output shows which repos have ✅/⚠️/❌ status
```

### 2. Normalize Script
**Location:** `shared-standards/scripts/normalize-quality-gate.sh`

Deploys quality-gate files to single repo:
```bash
./scripts/normalize-quality-gate.sh /path/to/repo [--force]
```

**Creates:**
- `scripts/quality_gate.py` (260 lines, portable)
- `.quality-gate.json` (repo-specific commands)
- `.github/workflows/quality-gate-check.yml` (GitHub Actions workflow)
- `makefiles/quality-gate.Makefile` (Make targets)

**Auto-detects repo type:**
- Python: uses `make tests`, `make lint`, `make type-check`
- Node.js: uses `npm test`, `npm run lint`, `npm run type-check`
- Mixed: defaults to generic `make` targets

### 3. Batch Script
**Location:** `shared-standards/scripts/batch-normalize-quality-gate.sh`

Deploys to multiple repos in sequence:
```bash
# Deploy to Phase 1 repos
./scripts/batch-normalize-quality-gate.sh

# Deploy to specific repos
./scripts/batch-normalize-quality-gate.sh --repos=repo1,repo2,repo3

# Force overwrite existing files
./scripts/batch-normalize-quality-gate.sh --force
```

## Deployment Process (Per Repo)

### Step 1: Run normalization
```bash
cd ~/Documents/perso/projects
./chrysa/shared-standards/scripts/normalize-quality-gate.sh ./chrysa/lifeos
```

### Step 2: Review and adjust
```bash
cd ./chrysa/lifeos

# Review generated .quality-gate.json
cat .quality-gate.json
# Edit if Make command names differ from standard ones
# (e.g., repo uses "make test" instead of "make tests")

vim .quality-gate.json  # if needed
```

### Step 3: Test baseline
```bash
# Record baseline metrics
make quality-gate-baseline

# Check baseline file was created
ls -la .quality-gate-baseline.json
```

### Step 4: Test verification
```bash
# Verify against baseline
make quality-gate-verify

# Should show all gates passing if no regressions
```

### Step 5: Commit
```bash
git add -A
git commit -m "chore: add quality gate setup (OPS-190)"
git push
```

### Step 6: Verify workflow
```bash
# Create test PR to verify GitHub Actions workflow
git checkout -b test/quality-gate-validation
echo "# Test PR" >> README.md
git add README.md
git commit -m "test: verify quality gate workflow"
git push origin test/quality-gate-validation

# Go to GitHub → Actions tab
# Verify "quality-gate-check" workflow runs successfully
```

## Key Customizations by Repo Type

### Python-Heavy Repos
```json
{
  "commands": {
    "tests": "make tests",           # pytest runner
    "coverage": "make tests-cov",    # coverage report
    "lint": "make lint",              # ruff/pylint
    "types": "make type-check",       # mypy
    "build": "make build"
  }
}
```

### Node.js-Heavy Repos
```json
{
  "commands": {
    "tests": "npm test",
    "coverage": "npm run test:coverage",
    "lint": "npm run lint",
    "types": "npm run type-check",
    "build": "npm run build"
  }
}
```

### Mixed Repos
```json
{
  "commands": {
    "tests": "make test",
    "coverage": "make test-coverage",
    "lint": "make lint",
    "types": "make type-check",
    "build": "make build"
  }
}
```

## Rollout Checklist

### Before deployment
- [ ] Audit complete, repos categorized
- [ ] Normalization script tested on at least 1 repo
- [ ] OPS-187 (workflows) deployed and validated
- [ ] OPS-188 (branch protection) ready to apply

### During Phase 1 (Week 1)
- [ ] Run `batch-normalize-quality-gate.sh` for Phase 1 repos
- [ ] Review `.quality-gate.json` in each repo
- [ ] Test: `make quality-gate-baseline && make quality-gate-verify`
- [ ] Commit & push changes
- [ ] Monitor first PR workflows in Actions tab
- [ ] Adjust Make commands if workflow fails

### Milestones
- [ ] Phase 1 (6 repos) normalized by EOW1
- [ ] Phase 2 (6 repos) normalized by EOW2
- [ ] Phase 3 (20 repos) normalized by EOW3
- [ ] 100% of active repos at parity

## Troubleshooting

### Make targets differ from standard names
**Issue:** Workflow fails because repo uses `make unittest` instead of `make tests`

**Solution:**
1. List available targets: `make help` or `grep "^[a-z].*:" Makefile`
2. Update `.quality-gate.json` with correct command
3. Re-run: `make quality-gate-baseline && make quality-gate-verify`

### Workflow timeout
**Issue:** Workflow takes > 5 min, times out

**Solution:**
1. Check which command is slow: run locally and time each
2. Optimize slow Make targets
3. Or adjust workflow timeout in `.github/workflows/quality-gate-check.yml`

### Python/Node dependencies missing
**Issue:** Workflow error: "Module not found" or "Command not found"

**Solution:**
1. Add missing dependency to `.quality-gate-json` setup step
2. Or ensure `requirements.txt` / `package.json` exists in repo
3. Test locally first: `make quality-gate-baseline`

## Monitoring & Metrics

After full rollout, track:
- **Adoption rate:** % of active repos with complete setup
- **Workflow success:** % of PR workflows passing
- **Regression catches:** How many regressions were caught before merge
- **Developer friction:** Any reported delays or frustrations

## Rollback Plan

If issues emerge during deployment:
1. Pause batch deployments (don't run script on more repos)
2. Fix issues on deployed repos (adjust `.quality-gate.json` or scripts)
3. Test fix on 1-2 repos before resuming

## Dependencies & Blockers

- ✅ **OPS-187** (workflow deployment) — Must complete first
- ⏳ **OPS-188** (branch protection) — Not required for OPS-190, but should follow

## Success Criteria

- [ ] 100% of active repos have quality-gate files
- [ ] All workflows trigger successfully on PRs
- [ ] All baseline recordings complete without error
- [ ] Regression verification working in at least 3 repos
- [ ] Team feedback incorporated, no critical issues

## Related Tasks
- **OPS-187** (completed): GitHub Actions workflow deployment
- **OPS-188**: Branch protection for required status checks
- **OPS-189** (P2): Weekly baseline freshness review

---

**Owner:** CI/CD Team
**Timeline:** 3 weeks (Weeks 1-3 of Month)
**Status:** In Progress
**Created:** 27 avril 2026
