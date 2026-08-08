# Claude Code Hook Suite

Shared DevEx/LLM tooling for the ecosystem.
All hooks are written in Node.js (`.cjs`) and require only the standard library.

---

## Hooks overview

| Hook | Type | File | Blocks? |
|------|------|------|---------|
| Secret scanner | `PreToolUse` (Bash → git commit) | `secret-scanner.cjs` | Yes (exit 2) |
| No-env-files | `PreToolUse` (Bash → git commit) · CLI `--ci` | `check-no-env-files.cjs` | Yes (exit 2) · CI exit 1 |
| Circuit breaker | `PreToolUse` (Bash → API calls) | `circuit-breaker.cjs` | Yes when open (exit 2) |
| Frustration detection | `UserPromptSubmit` | `frustration-detection.cjs` | No (injects context) |
| Verifiable thresholds | `PostToolUse` (Write/Edit) | `verifiable-thresholds.cjs` | No (warnings only) |
| Memory consolidation | CLI script | `memory-consolidation.cjs` | N/A |
| Model debt inventory | CLI script | `model-debt-inventory.cjs` | N/A |

---

## 1. Secret Scanner

**Purpose:** Block `git commit` if staged files contain secret patterns.

**Detected secrets:**
- Anthropic, OpenAI, AWS, GitHub, Slack, Stripe API keys
- JWT tokens with real payload
- PEM/RSA private keys
- Generic secret assignments (password=, token=, etc.)

**How to test:**
```bash
# Blocking case
echo 'API_KEY = "sk-ant-testing1234567890abcdef"' > /tmp/test_secret.py
git add /tmp/test_secret.py
echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m test"}}' \
  | node .claude/hooks/secret-scanner.cjs
# Expected: exit 2, message about Anthropic API key

# Non-blocking case
echo '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}' \
  | node .claude/hooks/secret-scanner.cjs
# Expected: exit 0, no output
```

**Disable for a line:** Add `# nosecret` or `// nosecret` on the line.

**Allowlist file:** `.claude/secret-scanner-allowlist.json`
```json
{
  "patterns": ["sk-test-placeholder"],
  "files": ["tests/fixtures"]
}
```

**Known false positives:**
- Long random strings in test fixtures that match the generic pattern
- Example tokens in documentation

---

## 2. Circuit Breaker

**Purpose:** Block API-like `curl`/`wget`/`fetch` calls after 3 consecutive failures. Prevents retry storms.

**States:** `closed` → `open` → `half-open` → `closed`

**State file:** `~/.claude/circuit-breaker-state.json`

**Configuration:**
```bash
CB_FAILURE_THRESHOLD=3       # failures before opening (default: 3)
CB_RESET_TIMEOUT_MS=60000    # ms before half-open trial (default: 60s)
CB_STATE_FILE=/custom/path   # state file path
```

**As a library** (from other scripts):
```js
const cb = require('.claude/hooks/circuit-breaker.cjs');

if (cb.canCall('my-api')) {
  try {
    await callApi();
    cb.recordSuccess('my-api');
  } catch (e) {
    cb.recordFailure('my-api');
  }
}
```

**How to test:**
```bash
# Simulate 3 failures then check state
node -e "
const cb = require('.claude/hooks/circuit-breaker.cjs');
cb.recordFailure('test'); cb.recordFailure('test'); cb.recordFailure('test');
console.log(cb.getState('test')); // { state: 'open', ... }
console.log(cb.canCall('test'));  // false
cb.reset('test');
console.log(cb.canCall('test'));  // true
"
```

---

## 3. Frustration Detection

**Purpose:** Detect frustration/debug markers or continuation requests in prompts and inject guidance context.

**Logic:**
- **Frustration** (`why isn't it working`, `ugh`, `still failing`, `!!!`) → inject "be direct, short, resolution-only" context
- **Continuation** (`continue`, `finish this`, `don't summarize`) → inject "pick up where you left off" context
- **Debug signal** (`error:`, `traceback`, `why is X failing`) → inject "root cause + minimal fix" context

**How to test:**
```bash
echo '{"prompt":"why isnt this working!!!"}' | node .claude/hooks/frustration-detection.cjs
# Expected: JSON inject_prompt with frustration context

echo '{"prompt":"continue"}' | node .claude/hooks/frustration-detection.cjs
# Expected: JSON inject_prompt with continuation context

echo '{"prompt":"implement a function to sort a list"}' | node .claude/hooks/frustration-detection.cjs
# Expected: exit 0, no output
```

**Adjust patterns:** Edit `FRUSTRATION_PATTERNS`, `CONTINUATION_PATTERNS`, `DEBUG_PATTERNS` arrays in the file.

---

## 4. Verifiable Thresholds

**Purpose:** Warn (not block) when written files exceed measurable quality thresholds.

**Thresholds config:** `.claude/thresholds.json`
```json
{
  "max_function_lines": 50,
  "max_file_lines": 500,
  "max_cyclomatic_complexity": 10,
  "no_todo_fixme_in_new_code": true
}
```

**How to test:**
```bash
# Create a file that exceeds limits
python3 -c "print('\n'.join(['def foo():'] + ['    x = 1' for _ in range(60)]))" > /tmp/big_func.py
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/big_func.py"}}' \
  | node .claude/hooks/verifiable-thresholds.cjs
# Expected: warning about function too long on stderr, exit 0

# Non-triggering case
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/big_func.py"}}' \
  | node .claude/hooks/verifiable-thresholds.cjs
# Expected: exit 0, no output (Read tool is not targeted)
```

**Limits:**
- Function detection is heuristic (not AST). Complex arrow functions or decorators may be missed.
- Complexity is a rough estimate. Use ESLint `complexity` rule or `radon` for accurate CI enforcement.

---

## 5. Memory Consolidation (CLI)

**Purpose:** Clean `.claude/` directory from duplicate content, broken file references, and contradictions.

```bash
# Dry run — show what would change without writing
node .claude/hooks/memory-consolidation.cjs --dry-run

# Apply changes
node .claude/hooks/memory-consolidation.cjs

# Target a specific directory
node .claude/hooks/memory-consolidation.cjs --dir /path/to/any/.claude

# Verbose output
node .claude/hooks/memory-consolidation.cjs --dry-run --verbose
```

**What it does:**
- Deduplicates Markdown sections with identical content
- Flags references to files that no longer exist (adds `<!-- ⚠️ file not found -->` comment)
- Reports everything cleanly

---

## 6. Model Debt Inventory (CLI)

**Purpose:** Find all `@[MODEL_NAME]` tags in `.claude/` files and produce an inventory.

**Tagging convention:**
```markdown
<!-- @[claude-sonnet-4-6] — This rule only makes sense for Claude Sonnet 4 -->
- Keep responses under 200 words
```

```bash
# Human-readable report
node .claude/hooks/model-debt-inventory.cjs

# JSON output for scripting
node .claude/hooks/model-debt-inventory.cjs --json

# Scan a specific directory
node .claude/hooks/model-debt-inventory.cjs --dir /path/to/repo
```

---

## Installation in a repository

1. Copy the hooks to `.claude/hooks/` in your target repository
2. Merge with your existing `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "sh -c 'f=\"$CLAUDE_PROJECT_DIR/.claude/hooks/secret-scanner.cjs\"; [ ! -f \"$f\" ] || node \"$f\"'" },
          { "type": "command", "command": "sh -c 'f=\"$CLAUDE_PROJECT_DIR/.claude/hooks/circuit-breaker.cjs\"; [ ! -f \"$f\" ] || node \"$f\"'" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          { "type": "command", "command": "sh -c 'f=\"$CLAUDE_PROJECT_DIR/.claude/hooks/verifiable-thresholds.cjs\"; [ ! -f \"$f\" ] || node \"$f\"'" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "sh -c 'f=\"$CLAUDE_PROJECT_DIR/.claude/hooks/frustration-detection.cjs\"; [ ! -f \"$f\" ] || node \"$f\"'" }
        ]
      }
    ]
  }
}
```

3. Adjust `.claude/thresholds.json` for your project standards
4. Add `.claude/secret-scanner-allowlist.json` if you have test fixtures with example tokens

> **Always use the guarded command form** shown above
> (`sh -c 'f="$CLAUDE_PROJECT_DIR/.claude/hooks/<hook>.cjs"; [ ! -f "$f" ] || node "$f"'`),
> never a bare `node .claude/hooks/<hook>.cjs`. A bare invocation in a repo where the hook
> file is absent makes Node exit with `MODULE_NOT_FOUND`, which Claude Code reports on every
> single tool call as:
> `PreToolUse:Bash hook error - Failed with non-blocking status code: node:internal/modules/cjs/loader:<line>`.
> The guard turns a missing hook into a silent no-op, and `$CLAUDE_PROJECT_DIR` makes the
> path independent of the tool's working directory.

## No-env-files hook (`check-no-env-files.cjs`) — enforces AG-005

Blocks a commit that stages a `.env`-class secret file, and doubles as a CI gate.
Config is injected at runtime (env / secret store), never committed — Rain-devkit model.

```bash
# PreToolUse (blocking) — reads the tool payload on stdin
echo '{"tool_input":{"command":"git commit -m x"}}' | node .claude/hooks/check-no-env-files.cjs
# Expected: exit 2 if a staged path is `.env` / `.env.<x>` (not *.example|sample|template|dist)

# CI gate — scan the whole tree, wire into `make ci`
node .claude/hooks/check-no-env-files.cjs --ci .
# Expected: exit 1 on any tracked/present .env secret file, else 0
```

**Allowed, never flagged:** `*.env.example`, `*.env.sample`, `*.env.template`, `*.env.dist`.
**Allowlist file:** `.claude/no-env-allowlist.json` (JSON array of glob patterns).

## Disabling a hook

Remove or comment out its entry in `settings.json`.
For the secret scanner, use `# nosecret` on a specific line or add to the allowlist.
