import { useTranslation } from "react-i18next";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import type { Meta } from "@/api/types";

export type Tab = "fleet" | "distribution" | "standard";

interface NavProps {
  tab: Tab;
  onTab: (t: Tab) => void;
  meta?: Meta;
}

export function Nav({ tab, onTab, meta }: NavProps) {
  const { t, i18n } = useTranslation();
  const tabs: Tab[] = ["fleet", "distribution", "standard"];
  const toggleLang = () => void i18n.changeLanguage(i18n.language === "fr" ? "en" : "fr");
  const toggleTheme = () => document.documentElement.classList.toggle("dark");

  return (
    <header className="flex items-center gap-6 border-b border-border bg-card px-5 py-3">
      <b className="text-primary">⬡ standards console</b>
      <nav className="flex gap-1" aria-label="Sections">
        {tabs.map((id) => (
          <Button
            key={id}
            variant={tab === id ? "outline" : "ghost"}
            size="sm"
            aria-current={tab === id ? "page" : undefined}
            className={cn(tab === id && "text-foreground")}
            onClick={() => onTab(id)}
          >
            {t(`nav.${id}`)}
          </Button>
        ))}
      </nav>
      <div className="ml-auto flex items-center gap-3 text-sm text-muted-foreground">
        {meta && (
          <span>
            {meta.standards_full_name}@{meta.branch}
          </span>
        )}
        <Button variant="ghost" size="sm" onClick={toggleLang} aria-label="Toggle language">
          {i18n.language === "fr" ? "EN" : "FR"}
        </Button>
        <Button variant="ghost" size="icon" onClick={toggleTheme} aria-label="Toggle theme">
          ◑
        </Button>
      </div>
    </header>
  );
}
