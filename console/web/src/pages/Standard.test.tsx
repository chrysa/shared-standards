import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import "@/i18n";
import { Standard } from "./Standard";

afterEach(() => vi.restoreAllMocks());

function renderStandard(response: Partial<Response> & { json?: () => Promise<unknown> }) {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(response));
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <Standard meta={undefined} />
    </QueryClientProvider>,
  );
}

describe("Standard", () => {
  it("shows the editor once the standard loads", async () => {
    renderStandard({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ text: "50 lines/function", path: "STANDARDS.md" }),
    });
    await waitFor(() =>
      expect(screen.getByRole("textbox", { name: /standard/i })).toHaveValue("50 lines/function"),
    );
  });

  it("hides the editor and keeps the PR button unrenderable on load failure", async () => {
    // 502: GET /api/standard failed -> data undefined, isError true.
    renderStandard({ ok: false, status: 502, json: () => Promise.resolve({}) });
    await waitFor(() => expect(screen.getByRole("alert")).toBeInTheDocument());
    // The editor must not exist, so no empty PR can ever be opened from this state.
    expect(screen.queryByRole("textbox")).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /open pr|ouvrir une pr/i })).not.toBeInTheDocument();
  });
});
