# E2E scaffold (Playwright) — chrysa `fullstack` standard

Local-dev end-to-end tests. Playwright runs **inside the official docker image**
via `make e2e` — never on the host (per chrysa execution rules). Not wired into
CI; it is a `make`-driven dev-loop check.

## Wire it into a fullstack repo

1. Copy this folder's contents into your frontend dir:
   ```
   frontend/playwright.config.ts
   frontend/tests/e2e/smoke.spec.ts
   ```
   (Auth-gated app? Also copy `fixtures.ts.example` → `frontend/tests/e2e/fixtures.ts`.)

2. Add the dev dependency + scripts to `frontend/package.json`:
   ```jsonc
   "devDependencies": { "@playwright/test": "^1.60.0" },
   "scripts": {
     "test:e2e": "playwright test",
     "test:e2e:headed": "playwright test --headed"
   }
   ```

3. Set `baseURL`'s default port in `playwright.config.ts` to your stack's
   frontend port (the `docker-compose.yml` published port).

4. Add the canonical `e2e` / `e2e-headed` targets to your `Makefile`
   (see [MAKEFILE-STANDARD.md](https://github.com/chrysa/shared-standards/blob/main/docs/MAKEFILE-STANDARD.md)), setting `E2E_PORT` to the same port.

5. Ignore artefacts: `frontend/playwright-report/`, `frontend/test-results/`.

## Run

```bash
make docker-up   # bring the stack up (frontend on the configured port)
make e2e         # Playwright in docker against the running stack
make docker-down
```

Failures leave a trace + screenshots under `frontend/playwright-report/`.
Reference implementation: `chrysa/discordium`.
