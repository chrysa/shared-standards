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
