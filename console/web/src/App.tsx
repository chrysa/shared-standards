import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/api/client";
import { Nav, type Tab } from "@/components/Nav";
import { Fleet } from "@/pages/Fleet";
import { Distribution } from "@/pages/Distribution";
import { Standard } from "@/pages/Standard";
import { enterProps } from "@/lib/enter";

export function App() {
  const [tab, setTab] = useState<Tab>("fleet");
  const { data: meta } = useQuery({ queryKey: ["meta"], queryFn: api.meta });

  return (
    <>
      <Nav tab={tab} onTab={setTab} meta={meta} />
      <main className="mx-auto max-w-5xl p-6">
        {/* keyed by tab: a view change re-mounts the view, so its entrance plays once (FE-053) */}
        <div key={tab} {...enterProps()}>
          {tab === "fleet" && <Fleet meta={meta} />}
          {tab === "distribution" && <Distribution />}
          {tab === "standard" && <Standard meta={meta} />}
        </div>
      </main>
    </>
  );
}
