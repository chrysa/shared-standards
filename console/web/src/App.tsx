import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/api/client";
import { Nav, type Tab } from "@/components/Nav";
import { Fleet } from "@/pages/Fleet";
import { Distribution } from "@/pages/Distribution";
import { Standard } from "@/pages/Standard";

export function App() {
  const [tab, setTab] = useState<Tab>("fleet");
  const { data: meta } = useQuery({ queryKey: ["meta"], queryFn: api.meta });

  return (
    <>
      <Nav tab={tab} onTab={setTab} meta={meta} />
      <main className="mx-auto max-w-5xl p-6">
        {tab === "fleet" && <Fleet meta={meta} />}
        {tab === "distribution" && <Distribution />}
        {tab === "standard" && <Standard meta={meta} />}
      </main>
    </>
  );
}
