import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Fleet } from "./Fleet";

afterEach(() => vi.restoreAllMocks());

function renderFleet(rows: unknown[]) {
  vi.stubGlobal(
    "fetch",
    vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ rows, central_unreachable: null }),
    }),
  );
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <Fleet meta={undefined} />
    </QueryClientProvider>,
  );
}

describe("Fleet", () => {
  it("renders rows from the API", async () => {
    renderFleet([
      { name: "alpha", status: "dev", runtime: "container", archived: false, in_manifest: true, html_url: "u", compliance: null },
    ]);
    await waitFor(() => expect(screen.getByText("alpha")).toBeInTheDocument());
  });
});

describe("Fleet load failure", () => {
  it("shows the error with a retry action and no empty table", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 503, statusText: "Service Unavailable", json: () => Promise.resolve({ detail: "Server unreachable" }) })
      .mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ rows: [{ name: "beta", status: "dev", runtime: null, archived: false, in_manifest: false, html_url: "u", compliance: null }], central_unreachable: null }),
      });
    vi.stubGlobal("fetch", fetchMock);
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={qc}>
        <Fleet meta={undefined} />
      </QueryClientProvider>,
    );
    const alert = await screen.findByRole("alert");
    expect(alert).toHaveTextContent("Server unreachable");
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
    screen.getByRole("button", { name: "Retry" }).click();
    await waitFor(() => expect(screen.getByText("beta")).toBeInTheDocument());
  });
});
