# Testing OPS-187: Quality Gate Workflow Verification

## Quick Test Procedure

### Step 1: Create test branch
```bash
cd /path/to/repo  # e.g., padam-av or padam-av-backoffice
git checkout -b test/quality-gate-workflow
```

### Step 2: Ensure baseline exists
```bash
# Record baseline if not already done
make quality-gate-baseline
# This creates .quality-gate-baseline.json
```

### Step 3: Push and create PR
```bash
git add .
git commit -m "test: verify quality gate workflow"
git push origin test/quality-gate-workflow
# Then create PR on GitHub
```

### Step 4: Monitor workflow execution
1. Go to **Actions** tab in GitHub repo
2. Find workflow run for your branch
3. Verify job "quality-gate" executes
4. Check PR "Checks" tab for status check "quality-gate"

### Step 5: Verify workflow logic
- ✅ Workflow runs automatically on PR open/sync
- ✅ Status check named "quality-gate" appears
- ✅ Green check if all gates pass
- ✅ Red X if regression detected

### Step 6: Test regression detection
To test that regression blocking works:

```bash
# Introduce deliberate regression (e.g., break a test)
# Edit a test file to make it fail
git add .
git commit -m "test: deliberately break test to verify workflow catch"
git push origin test/quality-gate-workflow

# Monitor Actions tab
# Verify workflow runs again
# Verify status check shows red X (failed)
# Verify PR cannot be merged
```

## Success Criteria

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| Workflow triggered on PR | Yes | ? | ⬜ |
| Job completes in < 5 min | Yes | ? | ⬜ |
| Status check appears | Yes | ? | ⬜ |
| Status check passes (green) | Yes | ? | ⬜ |
| Status check fails on regression | Yes | ? | ⬜ |
| PR blocks merge on failed check | Yes | ? | ⬜ |

## Troubleshooting

### Workflow doesn't run
- [ ] `.github/workflows/quality-gate-check.yml` exists in repo
- [ ] GitHub Actions are enabled (Settings → Actions)
- [ ] Branch name matches trigger (main/master/develop for push, or any for PR)
- [ ] Commit is on the branch

### Workflow errors
- [ ] Check Actions tab for error messages
- [ ] Verify Make targets exist: `make quality-gate-verify`
- [ ] Verify dependencies installed (Python, Node, etc.)
- [ ] Check logs in workflow run details

### Status check not appearing
- [ ] Workflow must complete at least once (success or failure)
- [ ] Status check name in branch protection must match job name: `quality-gate`
- [ ] Refresh PR page to see updates

## Next Steps (After Successful Test)

1. ✅ OPS-187 validated
2. → Proceed to OPS-188: Apply branch protection to main branches
3. → Monitor first few PRs for workflow execution
4. → Document any adjustments needed

## Cleanup

After testing:
```bash
# Delete test branch
git branch -D test/quality-gate-workflow
git push origin --delete test/quality-gate-workflow

# Remove temporary baseline if desired
rm .quality-gate-baseline.json
```

---

**Created:** 27 avril 2026
**For:** OPS-187 validation
**Location:** All target repos' docs/testing guides
