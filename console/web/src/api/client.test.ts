import { afterEach, describe, expect, it, vi } from "vitest";
import { api, ApiError } from "./client";

afterEach(() => vi.restoreAllMocks());

function mockFetch(status: number, body: unknown) {
  return vi.fn().mockResolvedValue({
    ok: status < 400,
    status,
    statusText: "x",
    json: () => Promise.resolve(body),
  });
}

describe("api client", () => {
  it("returns parsed json on success", async () => {
    vi.stubGlobal("fetch", mockFetch(200, { rows: [] }));
    await expect(api.fleet()).resolves.toEqual({ rows: [] });
  });

  it("throws ApiError carrying the backend detail on failure", async () => {
    vi.stubGlobal("fetch", mockFetch(502, { detail: "GitHub API 403" }));
    await expect(api.fleet()).rejects.toMatchObject({
      constructor: ApiError,
      status: 502,
      message: "GitHub API 403",
    });
  });

  it("posts the status payload", async () => {
    const f = mockFetch(200, { ok: true, message: "x → dev" });
    vi.stubGlobal("fetch", f);
    await api.setStatus("repo", "dev");
    expect(f).toHaveBeenCalledWith("/api/repos/repo/status", expect.objectContaining({ method: "POST" }));
  });
});
