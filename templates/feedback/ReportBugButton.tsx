// chrysa canonical "Report a bug" component.
//
// Self-contained drop-in: a floating button + modal that POSTs a bug report to
// the app's OWN backend (`/api/v1/feedback` by default), which forwards it to
// feedback-gateway → GitHub issue. No GitHub credential reaches the browser.
//
// Adoption:
//   1. Copy this file + consoleTail.ts into the app's frontend.
//   2. Render <ReportBugButton /> once in the app shell / root layout.
//   3. If the app's API is not at /api/v1, pass `endpoint="/v1/feedback"`.
//   4. Swap the neutral Tailwind classes below for the app's design tokens
//      (e.g. bg-primary / text-foreground) where one exists. See gaming-os
//      (frontend/src/components/ReportBugButton.tsx) for a token-styled example.
//
// Requires: React 18+, Tailwind, lucide-react, and consoleTail.ts (same dir).

import { useEffect, useId, useState } from "react";
import { Bug, CheckCircle2, ExternalLink, Loader2, X } from "lucide-react";
import { getConsoleTail, installConsoleTail } from "./consoleTail";

type Severity = "Critical" | "High" | "Medium" | "Low";
const SEVERITIES: Severity[] = ["Critical", "High", "Medium", "Low"];

interface ReportBugButtonProps {
  /** Backend feedback endpoint. Defaults to the chrysa convention. */
  endpoint?: string;
  /** App version surfaced in the issue body for triage. */
  appVersion?: string;
}

type SubmitState =
  | { status: "idle" }
  | { status: "sending" }
  | { status: "sent"; url: string; deduplicated: boolean }
  | { status: "error"; message: string };

export function ReportBugButton({
  endpoint = "/api/v1/feedback",
  appVersion = "",
}: ReportBugButtonProps = {}) {
  const [open, setOpen] = useState(false);

  useEffect(() => {
    installConsoleTail();
  }, []);

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Report a bug"
        className="fixed bottom-5 right-5 z-40 grid h-12 w-12 place-items-center rounded-full border border-zinc-300 bg-white text-zinc-500 shadow-lg transition-colors hover:text-zinc-900 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-400 dark:hover:text-zinc-50"
      >
        <Bug size={20} aria-hidden="true" />
      </button>
      {open && (
        <ReportBugDialog
          endpoint={endpoint}
          appVersion={appVersion}
          onClose={() => setOpen(false)}
        />
      )}
    </>
  );
}

function ReportBugDialog({
  endpoint,
  appVersion,
  onClose,
}: {
  endpoint: string;
  appVersion: string;
  onClose: () => void;
}) {
  const titleId = useId();
  const [submit, setSubmit] = useState<SubmitState>({ status: "idle" });
  const [form, setForm] = useState({
    title: "",
    description: "",
    severity: "Medium" as Severity,
    website: "", // honeypot
  });

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const canSubmit =
    form.title.trim().length >= 3 && form.description.trim().length >= 1;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!canSubmit || submit.status === "sending") return;
    setSubmit({ status: "sending" });
    try {
      const res = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: form.title.trim(),
          description: form.description.trim(),
          severity: form.severity,
          website: form.website,
          environment: {
            url: window.location.href,
            user_agent: navigator.userAgent,
            app_version: appVersion,
            console_tail: getConsoleTail(),
          },
        }),
      });
      if (!res.ok) throw new Error(`Report failed (${res.status}).`);
      const data = (await res.json()) as {
        issue_url: string;
        deduplicated: boolean;
      };
      setSubmit({
        status: "sent",
        url: data.issue_url,
        deduplicated: data.deduplicated,
      });
    } catch (err) {
      setSubmit({
        status: "error",
        message: err instanceof Error ? err.message : "Something went wrong.",
      });
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 grid place-items-center bg-black/60 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-lg overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-2xl dark:border-zinc-700 dark:bg-zinc-900"
      >
        <header className="flex items-center justify-between border-b border-zinc-200 px-5 py-4 dark:border-zinc-700">
          <h2
            id={titleId}
            className="flex items-center gap-2 text-base font-bold text-zinc-900 dark:text-zinc-50"
          >
            <Bug size={18} aria-hidden="true" />
            Report a bug
          </h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="rounded p-1 text-zinc-500 hover:bg-zinc-100 hover:text-zinc-900 dark:hover:bg-zinc-800 dark:hover:text-zinc-50"
          >
            <X size={18} aria-hidden="true" />
          </button>
        </header>

        {submit.status === "sent" ? (
          <div className="flex flex-col items-center gap-3 p-8 text-center">
            <CheckCircle2 size={36} className="text-emerald-500" aria-hidden="true" />
            <p className="font-medium text-zinc-900 dark:text-zinc-50">
              {submit.deduplicated
                ? "Thanks — this was already reported. We added your note."
                : "Thanks — your report was filed."}
            </p>
            {submit.url && (
              <a
                href={submit.url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 text-sm text-blue-600 hover:underline dark:text-blue-400"
              >
                View the issue
                <ExternalLink size={14} aria-hidden="true" />
              </a>
            )}
            <button
              type="button"
              onClick={onClose}
              className="mt-2 rounded-lg bg-zinc-900 px-4 py-2 text-sm font-medium text-white dark:bg-zinc-100 dark:text-zinc-900"
            >
              Done
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="flex flex-col gap-4 p-5">
            <label htmlFor="bug-title" className="flex flex-col gap-1.5">
              <span className="text-sm font-medium text-zinc-900 dark:text-zinc-50">
                Title
              </span>
              <input
                id="bug-title"
                type="text"
                required
                minLength={3}
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                placeholder="Short summary of the problem"
                className={inputCls}
              />
            </label>

            <label htmlFor="bug-desc" className="flex flex-col gap-1.5">
              <span className="text-sm font-medium text-zinc-900 dark:text-zinc-50">
                What happened?
              </span>
              <textarea
                id="bug-desc"
                required
                rows={4}
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
                placeholder="Describe the bug. Steps, expected vs actual help a lot."
                className={`${inputCls} resize-y`}
              />
            </label>

            <label htmlFor="bug-sev" className="flex flex-col gap-1.5">
              <span className="text-sm font-medium text-zinc-900 dark:text-zinc-50">
                Severity
              </span>
              <select
                id="bug-sev"
                value={form.severity}
                onChange={(e) =>
                  setForm({ ...form, severity: e.target.value as Severity })
                }
                className={inputCls}
              >
                {SEVERITIES.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </label>

            {/* Honeypot: visually hidden, off the tab order. Bots fill it. */}
            <input
              type="text"
              tabIndex={-1}
              autoComplete="off"
              aria-hidden="true"
              value={form.website}
              onChange={(e) => setForm({ ...form, website: e.target.value })}
              className="absolute left-[-9999px] h-0 w-0 opacity-0"
            />

            {submit.status === "error" && (
              <p className="text-sm text-red-600 dark:text-red-400" role="alert">
                {submit.message}
              </p>
            )}

            <div className="flex items-center justify-end gap-2 pt-1">
              <button
                type="button"
                onClick={onClose}
                className="rounded-lg px-4 py-2 text-sm font-medium text-zinc-600 hover:bg-zinc-100 dark:text-zinc-300 dark:hover:bg-zinc-800"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={!canSubmit || submit.status === "sending"}
                className="inline-flex items-center gap-2 rounded-lg bg-zinc-900 px-4 py-2 text-sm font-medium text-white disabled:opacity-50 dark:bg-zinc-100 dark:text-zinc-900"
              >
                {submit.status === "sending" && (
                  <Loader2 size={16} className="animate-spin" aria-hidden="true" />
                )}
                Send report
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

const inputCls =
  "w-full rounded-lg border border-zinc-300 bg-zinc-50 px-3 py-2 text-sm text-zinc-900 outline-none focus-visible:ring-2 focus-visible:ring-blue-500 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-50";
