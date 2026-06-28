# syntax=docker/dockerfile:1
# Multi-stage: build the SPA with Node, run the API with Python 3.14.

# ── web-builder: compile the React SPA into standards_console/web_dist ──────────
FROM node:22-alpine AS web-builder
WORKDIR /web
RUN corepack enable
COPY web/package.json web/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY web/ ./
RUN pnpm build

# ── base: shared Python runtime ────────────────────────────────────────────────
FROM python:3.14-slim AS base
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH"

# ── builder: install the backend into a venv ───────────────────────────────────
FROM base AS builder
RUN python -m venv /opt/venv
COPY pyproject.toml README.md ./
COPY standards_console/ ./standards_console/
RUN pip install --no-cache-dir .

# ── production: minimal image, non-root ────────────────────────────────────────
FROM base AS production
RUN useradd --create-home --uid 10001 app
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /standards_console /app/standards_console
COPY --from=web-builder /standards_console/web_dist /app/standards_console/web_dist
WORKDIR /app
USER app
EXPOSE 8765
ENV CONSOLE_HOST=0.0.0.0
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8765/api/health').status==200 else 1)"
CMD ["standards-console"]

# ── dev: include dev deps + source for live work ───────────────────────────────
FROM builder AS dev
RUN pip install --no-cache-dir -e '.[dev]'
COPY tests/ ./tests/
CMD ["standards-console"]
