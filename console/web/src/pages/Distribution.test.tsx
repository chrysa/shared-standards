import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import "@/i18n";
import { Distribution } from "./Distribution";

afterEach(() => vi.restoreAllMocks());

describe("Distribution", () => {
  it("introduces run rows with a capped stagger", async () => {
    const runs = Array.from({ length: 8 }, (_, i) => ({
      status: "completed",
      conclusion: i % 2 ? "success" : null,
      created_at: `2026-11-0${i + 1}`,
      html_url: `https://example.invalid/${i}`,
      event: "push",
    }));
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: () => Promise.resolve({ runs, pulls: [] }) }),
    );
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(
      <QueryClientProvider client={qc}>
        <Distribution />
      </QueryClientProvider>,
    );
    const rows = (await screen.findAllByRole("row")).slice(1);
    expect(rows).toHaveLength(8);
    expect(rows.every((row) => row.classList.contains("enter"))).toBe(true);
    expect(rows[7].style.getPropertyValue("--enter-index")).toBe("5");
    expect(screen.getByText("None")).toBeInTheDocument();
  });
});
