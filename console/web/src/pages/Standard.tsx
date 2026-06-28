import { useEffect, useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import { api } from "@/api/client";
import type { Meta } from "@/api/types";
import { Banner } from "@/components/Banner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

export function Standard({ meta }: { meta?: Meta }) {
  const { t } = useTranslation();
  const { data, isLoading } = useQuery({ queryKey: ["standard"], queryFn: api.standard });
  const [content, setContent] = useState("");
  const [summary, setSummary] = useState("");

  useEffect(() => {
    if (data) setContent(data.text);
  }, [data]);

  const edit = useMutation({
    mutationFn: () => api.editStandard(content, summary),
  });

  return (
    <section>
      <h1 className="mb-1 text-2xl font-semibold">
        {t("standard.title")} — <code className="text-base">{data?.path}</code>
      </h1>
      <p className="mb-4 text-sm text-muted-foreground">
        {t("standard.hint", { repo: meta?.standards_full_name, branch: meta?.branch })}
      </p>
      {edit.isError && <Banner kind="error">{(edit.error as Error).message}</Banner>}
      {edit.isSuccess && (
        <Banner kind="success">
          <a className="underline" href={edit.data.pr_url} target="_blank" rel="noopener noreferrer">
            {t("standard.prOpened", { number: edit.data.pr_number, branch: edit.data.branch })}
          </a>
        </Banner>
      )}
      {isLoading ? (
        <p className="text-muted-foreground">{t("common.loading")}</p>
      ) : (
        <>
          <Textarea
            value={content}
            spellCheck={false}
            aria-label={t("standard.title")}
            onChange={(e) => setContent(e.target.value)}
          />
          <div className="mt-3 flex gap-3">
            <Input
              className="flex-1"
              placeholder={t("standard.summary")}
              value={summary}
              onChange={(e) => setSummary(e.target.value)}
            />
            <Button disabled={edit.isPending} onClick={() => edit.mutate()}>
              {t("standard.openPr")}
            </Button>
          </div>
        </>
      )}
    </section>
  );
}
