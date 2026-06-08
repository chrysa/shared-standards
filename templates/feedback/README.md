# In-app "Report a bug" → GitHub issue

Lets an end user report a bug from any chrysa web app. The report travels:

```
Report-a-bug modal ──▶ app backend POST /api/v1/feedback
  (browser, same origin)      │  injects X-Feedback-Key (server-side env)
                              ▼
                  feedback-gateway POST /v1/reports
                    (single GitHub App key · dedup · rate-limit · honeypot)
                              ▼
                      GitHub issue on chrysa/<app>
```

The browser never holds a GitHub credential or the feedback app key — the key
lives only in the app backend's environment.

## Files

| File | Goes to | Purpose |
|------|---------|---------|
| `feedback_router.py` | app backend `app/routers/feedback.py` | proxy endpoint → feedback-gateway |
| `ReportBugButton.tsx` | app frontend `src/components/` | floating button + modal |
| `consoleTail.ts` | app frontend `src/lib/` | captures recent console errors for the report |

## Backend wiring

1. Copy `feedback_router.py` to `app/routers/feedback.py`.
2. Add two settings to the app's `Settings` (pydantic-settings):
   ```python
   feedback_gateway_url: str = ""   # e.g. http://feedback-gateway:8000
   feedback_app_key: str = ""       # this app's opaque key (server-side only)
   ```
3. Mount it where the app includes its other routers:
   ```python
   from app.routers.feedback import create_feedback_router
   app.include_router(
       create_feedback_router(settings.feedback_gateway_url, settings.feedback_app_key),
       prefix=API_PREFIX,
   )
   ```
   (gaming-os inlines a non-factory variant reading `settings` directly — either is fine.)
4. Set `FEEDBACK_GATEWAY_URL` and `FEEDBACK_APP_KEY` in the deploy env. Never as `VITE_*`.

## Frontend wiring

1. Copy `consoleTail.ts` to `src/lib/` and `ReportBugButton.tsx` to `src/components/`.
2. Render once in the app shell / root layout: `<ReportBugButton />`.
3. If the API base is not `/api/v1`, pass `endpoint="/v1/feedback"`.
4. Restyle the neutral Tailwind classes to the app's design tokens where one
   exists. gaming-os is the token-styled reference.

## Prerequisites (per repo)

- feedback-gateway deployed, with this repo's opaque key in `APP_REPO_MAP`.
- Labels `feedback` and `bug` exist on the repo (the gateway applies them).

## Contract

The payload mirrors `feedback-gateway/app/schemas.py` (`ReportRequest`). Keep the
field caps (`MAX_TITLE_LEN=160`, `MAX_TEXT_LEN=8000`, `MAX_CONSOLE_LINES=50`) and
the `X-Feedback-Key` header in sync if the gateway evolves.
