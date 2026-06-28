import { cn } from "@/lib/utils";

export function Banner({ kind, children }: { kind: "error" | "success"; children: React.ReactNode }) {
  return (
    <div
      role={kind === "error" ? "alert" : "status"}
      className={cn(
        "mb-4 rounded-md border px-3 py-2 text-sm",
        kind === "error"
          ? "border-destructive bg-destructive/10 text-destructive"
          : "border-success bg-success/10 text-success",
      )}
    >
      {children}
    </div>
  );
}
