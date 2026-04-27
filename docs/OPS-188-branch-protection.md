# OPS-188: Branch Protection for Quality Gates

## Overview
This task enforces the quality gate workflow as a required status check on main development branches. This ensures no code with regressions can be merged until all quality gates pass.

## Prerequisites
- ✅ OPS-187 complete: GitHub Actions workflow (`quality-gate-check.yml`) deployed in repos
- ✅ Workflow must have run successfully on at least one PR to establish the status check name
- Required permissions: Admin access to repository settings

## Configuration

### Via Script (Recommended)

```bash
# Set GitHub token
export GH_TOKEN=github_pat_xxxx...

# Run setup script in shared-standards repo
cd chrysa/shared-standards
./scripts/setup-branch-protection.sh <owner/repo>

# Example
./scripts/setup-branch-protection.sh anthony/padam-av
./scripts/setup-branch-protection.sh anthony/padam-av-backoffice
```

### Manual Configuration

For each target repository:

1. Go to **Settings** → **Branches**
2. Click **Add rule** under "Branch protection rules"
3. Apply to branches: `main`, `master`, `develop`
4. Enable:
   - ☑️ **Require a pull request before merging**
     - ☑️ Dismiss stale pull request approvals when new commits are pushed
     - ☑️ Require at least 1 approval
   - ☑️ **Require status checks to pass before merging**
     - ☑️ Require branches to be up to date before merging
     - Status check: `quality-gate`
   - ☑️ **Enforce all the above restrictions for administrators**

## Workflow Status Check Name

The GitHub Actions workflow reports a status check with name: `quality-gate`

This corresponds to:
```yaml
# From .github/workflows/quality-gate-check.yml
jobs:
  quality-gate:  # ← This job name becomes the check name
    runs-on: ubuntu-latest
```

## Verification

After applying branch protection:

1. Create a test PR that makes a code change
2. Verify:
   - ✅ Workflow `quality-gate-check` runs automatically
   - ✅ Status check "quality-gate" appears in PR checks
   - ✅ PR cannot be merged if check fails
   - ✅ PR can be merged once check passes

## Rollout Plan

### Phase 1 (Immediate - OPS-188)
- [ ] padam-av
- [ ] padam-av-backoffice

### Phase 2 (Week 1)
- [ ] chrysa/lifeos
- [ ] chrysa/server
- [ ] chrysa/coach

### Phase 3 (Week 2+)
- [ ] Remaining active chrysa repos
- [ ] Enable for all repos in chrysa + padam orgs

## Troubleshooting

### Workflow not running
- Check `.github/workflows/quality-gate-check.yml` exists in repo
- Verify GitHub Actions are enabled in repo settings
- Confirm branch matches `on:` triggers (main/master/develop)

### Status check not appearing
- First workflow run must complete (success or fail)
- Branch protection rule references correct check name: `quality-gate`
- Check repo Actions tab for workflow execution

### Cannot merge after check passes
- Verify `Require branches to be up to date before merging` is checked
- Ensure approvals requirement is met (if enabled)
- Check no other blocking status checks exist

### Override (Emergency Only)
If needed to merge despite failing check:
1. Requires admin access
2. Dismiss failing check (not recommended)
3. Document reason in PR comments
4. Fix regression immediately after merge

## Monitoring

After deployment, monitor:
- PR merge times (should not increase significantly)
- Failed checks (document if quality gates catch regressions)
- Developer feedback (friction/blockers)

## Rollback

To disable for a branch:
1. Go to Settings → Branches
2. Edit the branch protection rule
3. Uncheck status check requirement
4. Disable specific check or rule entirely

## Related Tasks
- **OPS-187** (completed): GitHub Actions workflow setup
- **OPS-190**: Normalize quality-gate integration across repos
- **OPS-189** (P2): Weekly baseline freshness review
