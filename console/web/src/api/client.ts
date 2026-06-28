import type {
  DistributionResponse,
  FleetResponse,
  Meta,
  Ok,
  StandardDoc,
  StandardEditResponse,
} from "./types";

export class ApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const resp = await fetch(`/api${path}`, {
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  if (!resp.ok) {
    const detail = await resp.json().catch(() => ({ detail: resp.statusText }));
    throw new ApiError(resp.status, detail.detail ?? resp.statusText);
  }
  return resp.json() as Promise<T>;
}

export const api = {
  meta: () => request<Meta>("/meta"),
  fleet: () => request<FleetResponse>("/fleet"),
  setStatus: (name: string, status: string) =>
    request<Ok>(`/repos/${name}/status`, { method: "POST", body: JSON.stringify({ status }) }),
  distribution: () => request<DistributionResponse>("/distribution"),
  runDistribution: (mode: "check" | "apply", only: string) =>
    request<Ok>("/distribution/run", { method: "POST", body: JSON.stringify({ mode, only }) }),
  standard: () => request<StandardDoc>("/standard"),
  editStandard: (content: string, summary: string) =>
    request<StandardEditResponse>("/standard", {
      method: "POST",
      body: JSON.stringify({ content, summary }),
    }),
};
