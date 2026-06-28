import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import { api } from "@/api/client";
import type { FleetRow, Meta } from "@/api/types";
import { Banner } from "@/components/Banner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";

function ComplianceBadge({ row }: { row: FleetRow }) {
  const { t } = useTranslation();
  if (!row.compliance) return <span className="text-muted-foreground">—</span>;
  const { errors, warnings } = row.compliance;
  return (
    <span className="flex gap-2">
      {errors ? (
        <Badge variant="destructive">{t("fleet.errors", { count: errors })}</Badge>
      ) : (
        <Badge variant="success">{t("fleet.clean")}</Badge>
      )}
      {warnings ? <Badge variant="warning">{t("fleet.warnings", { count: warnings })}</Badge> : null}
    </span>
  );
}

function StatusCell({ row, meta }: { row: FleetRow; meta?: Meta }) {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const [value, setValue] = useState(row.status);
  const mutation = useMutation({
    mutationFn: (status: string) => api.setStatus(row.name, status),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["fleet"] }),
  });
  return (
    <span className="flex items-center gap-2">
      <Select
        value={value}
        aria-label={`${t("fleet.status")} ${row.name}`}
        onChange={(e) => setValue(e.target.value)}
      >
        {(meta?.valid_status ?? []).map((s) => (
          <option key={s} value={s}>
            {s}
          </option>
        ))}
      </Select>
      <Button size="sm" variant="outline" disabled={mutation.isPending} onClick={() => mutation.mutate(value)}>
        {t("common.save")}
      </Button>
      {mutation.isError && <span className="text-destructive">✗</span>}
      {mutation.isSuccess && <span className="text-success">✓</span>}
    </span>
  );
}

export function Fleet({ meta }: { meta?: Meta }) {
  const { t } = useTranslation();
  const { data, isLoading, isError, error } = useQuery({ queryKey: ["fleet"], queryFn: api.fleet });

  return (
    <section>
      <h1 className="mb-1 text-2xl font-semibold">{t("fleet.title")}</h1>
      <p className="mb-4 text-sm text-muted-foreground">
        {t("fleet.subtitle", { manifest: "repos.yml" })}
        {meta && !meta.central_configured ? ` · ${t("fleet.centralOff")}` : ""}
      </p>
      {isError && <Banner kind="error">{(error as Error).message}</Banner>}
      {data?.central_unreachable && <Banner kind="error">{data.central_unreachable}</Banner>}
      {isLoading ? (
        <p className="text-muted-foreground">{t("common.loading")}</p>
      ) : (
        <Table>
          <THead>
            <TR>
              <TH>{t("fleet.repo")}</TH>
              <TH>{t("fleet.status")}</TH>
              <TH>{t("fleet.runtime")}</TH>
              <TH>{t("fleet.compliance")}</TH>
            </TR>
          </THead>
          <TBody>
            {data?.rows.map((row) => (
              <TR key={row.name}>
                <TD>
                  <a className="text-primary hover:underline" href={row.html_url} target="_blank" rel="noopener noreferrer">
                    {row.name}
                  </a>
                  {row.archived && <Badge className="ml-2">{t("fleet.archived")}</Badge>}
                  {!row.in_manifest && (
                    <Badge variant="warning" className="ml-2">
                      {t("fleet.notInManifest")}
                    </Badge>
                  )}
                </TD>
                <TD>{row.in_manifest ? <StatusCell row={row} meta={meta} /> : "—"}</TD>
                <TD>
                  <Badge>{row.runtime ?? "—"}</Badge>
                </TD>
                <TD>
                  <ComplianceBadge row={row} />
                </TD>
              </TR>
            ))}
          </TBody>
        </Table>
      )}
    </section>
  );
}
