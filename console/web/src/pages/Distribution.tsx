import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import { api } from "@/api/client";
import { Banner } from "@/components/Banner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/table";

export function Distribution() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const [only, setOnly] = useState("");
  const { data, isLoading } = useQuery({ queryKey: ["distribution"], queryFn: api.distribution });
  const run = useMutation({
    mutationFn: (mode: "check" | "apply") => api.runDistribution(mode, only),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["distribution"] }),
  });

  const onApply = () => {
    if (window.confirm(t("distribution.applyConfirm"))) run.mutate("apply");
  };

  return (
    <section>
      <h1 className="mb-4 text-2xl font-semibold">{t("distribution.title")}</h1>
      {run.isError && <Banner kind="error">{(run.error as Error).message}</Banner>}
      {run.isSuccess && <Banner kind="success">{run.data.message}</Banner>}

      <div className="mb-6 flex items-end gap-3">
        <label className="flex flex-col gap-1 text-sm">
          {t("distribution.subset")}
          <Input
            className="w-64"
            placeholder="repo-a,repo-b"
            value={only}
            onChange={(e) => setOnly(e.target.value)}
          />
        </label>
        <Button variant="outline" disabled={run.isPending} onClick={() => run.mutate("check")}>
          {t("distribution.check")}
        </Button>
        <Button disabled={run.isPending} onClick={onApply}>
          {t("distribution.apply")}
        </Button>
      </div>

      <h2 className="mb-2 text-lg font-semibold">{t("distribution.recentRuns")}</h2>
      {isLoading ? (
        <p className="text-muted-foreground">{t("common.loading")}</p>
      ) : (
        <Table>
          <THead>
            <TR>
              <TH>{t("distribution.when")}</TH>
              <TH>{t("distribution.event")}</TH>
              <TH>{t("fleet.status")}</TH>
              <TH>{t("distribution.result")}</TH>
            </TR>
          </THead>
          <TBody>
            {data?.runs.map((r) => (
              <TR key={r.html_url}>
                <TD>
                  <a className="text-primary hover:underline" href={r.html_url} target="_blank" rel="noopener noreferrer">
                    {r.created_at}
                  </a>
                </TD>
                <TD>{r.event}</TD>
                <TD>{r.status}</TD>
                <TD>
                  <Badge variant={r.conclusion === "success" ? "success" : r.conclusion ? "destructive" : "default"}>
                    {r.conclusion ?? "…"}
                  </Badge>
                </TD>
              </TR>
            ))}
          </TBody>
        </Table>
      )}

      <h2 className="mb-2 mt-6 text-lg font-semibold">{t("distribution.openPrs")}</h2>
      <ul className="list-disc pl-6 text-sm">
        {data?.pulls.length ? (
          data.pulls.map((p) => (
            <li key={p.number}>
              <a className="text-primary hover:underline" href={p.html_url} target="_blank" rel="noopener noreferrer">
                #{p.number} {p.title}
              </a>
            </li>
          ))
        ) : (
          <li className="list-none text-muted-foreground">{t("common.none")}</li>
        )}
      </ul>
    </section>
  );
}
