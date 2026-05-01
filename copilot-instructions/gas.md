# GitHub Copilot Instructions — Google Apps Script (GAS)

<!-- @[claude-sonnet-4] -->

Extends [base.md](base.md). Read base rules first; rules here take precedence where they conflict.

## Layout

```
<domain>/
  appsscript.json   # GAS manifest (scopes, timezone, runtimeVersion)
  .clasp.json       # clasp project config (scriptId, rootDir)
  helpers.gs        # shared utilities local to this domain
  <feature>.gs      # one file per logical feature or script
src/                # legacy flat structure (kept for backward compat if needed)
shared/             # cross-domain helpers (sync'd via clasp or copy-paste)
```

## Language

- Use ES2020 features: arrow functions, `const`/`let`, template literals, destructuring, optional chaining.
- No `var`. No CommonJS `require()` — GAS does not support modules.
- Globals provided by the GAS runtime (e.g. `SpreadsheetApp`, `GmailApp`) are available globally; declare them as globals in ESLint config.

## Script design

- Each `.gs` file must define a `CONFIG_<SCRIPT_NAME>` object at the top with all constants.
- Never inline magic strings or numbers — put them in `CONFIG_*`.
- Functions must be ≤ 50 lines. Extract helpers freely.
- Do not store secrets in source code — use `PropertiesService.getScriptProperties()`.

## Triggers

- All time-based triggers are documented in the script's `CONFIG_*` object under a `TRIGGERS` key.
- Trigger re-registration is manual (GAS dashboard) — document required triggers in the `README.md`.
- Use `LockService` for scripts that must not run concurrently.

## Error handling

- Wrap top-level trigger functions in `try/catch`; log errors with `console.error` or `Logger.log`.
- Send alert emails on critical failures using `MailApp.sendEmail` to a configurable address from `PropertiesService`.

## Deployment

- Deploy via `clasp push --force` (CI handles this automatically).
- CI only deploys changed domain folders (detected via `git diff`).
- Never push directly from local without running `make lint` first.

## Testing

- Unit tests use Jest with a GAS globals mock file (`__tests__/setup/gas-globals.js`).
- Test pure functions and transformation logic; do not test GAS API calls directly.
- Mock `PropertiesService`, `MailApp`, etc. in tests.

## Security

- Use `ScriptApp.getOAuthToken()` only when making authenticated API calls within GAS.
- All external API keys must be stored in Script Properties, never in `.gs` files.
- Validate all external webhook/request inputs before processing.
