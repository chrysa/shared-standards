export interface Meta {
  standards_full_name: string;
  branch: string;
  valid_status: string[];
  valid_runtime: string[];
  central_configured: boolean;
}

export interface ComplianceCell {
  errors: number;
  warnings: number;
  updated_at: string;
}

export interface FleetRow {
  name: string;
  status: string;
  runtime: string | null;
  archived: boolean | null;
  in_manifest: boolean;
  html_url: string;
  compliance: ComplianceCell | null;
}

export interface FleetResponse {
  rows: FleetRow[];
  central_unreachable: string | null;
}

export interface RunInfo {
  status: string;
  conclusion: string | null;
  created_at: string;
  html_url: string;
  event: string;
}

export interface PullInfo {
  number: number;
  title: string;
  html_url: string;
}

export interface DistributionResponse {
  runs: RunInfo[];
  pulls: PullInfo[];
}

export interface StandardDoc {
  path: string;
  text: string;
}

export interface StandardEditResponse {
  pr_number: number;
  pr_url: string;
  branch: string;
}

export interface Ok {
  ok: boolean;
  message: string;
}
