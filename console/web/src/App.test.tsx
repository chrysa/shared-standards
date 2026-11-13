import { afterEach, describe, expect, it, vi } from "vitest";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import "@/i18n";
import { App } from "./App";

afterEach(() => vi.restoreAllMocks());

const responses: Record<string, unknown> = {
  "/api/meta": { standards_full_name: "org/standards", branch: "develop", valid_status: ["dev"], valid_runtime: [], central_configured: true },
  "/api/fleet": { rows: [], central_unreachable: null },
  "/api/distribution": { runs: [], pulls: [] },
  "/api/standard": { path: "STANDARDS.md", text: "# Standards" },
};

function renderApp() {
  vi.stubGlobal(
    "fetch",
    vi.fn((url: string) =>
      Promise.resolve({ ok: true, status: 200, json: () => Promise.resolve(responses[url]) }),
    ),
  );
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <App />
    </QueryClientProvider>,
  );
}

describe("App", () => {
  it("re-mounts the active view on navigation so its entrance plays once", async () => {
    const { container } = renderApp();
    const firstView = container.querySelector("main > .enter");
    expect(firstView).not.toBeNull();
    fireEvent.click(screen.getByRole("button", { name: "Distribution" }));
    await waitFor(() => expect(screen.getByRole("heading", { name: "Distribution" })).toBeInTheDocument());
    const secondView = container.querySelector("main > .enter");
    expect(secondView).not.toBe(firstView);
    expect(screen.getByRole("button", { name: "Distribution" })).toHaveAttribute("aria-current", "page");
  });
});
