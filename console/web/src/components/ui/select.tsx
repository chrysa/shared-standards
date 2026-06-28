import * as React from "react";
import { cn } from "@/lib/utils";

// Native select styled to match the design system — keeps full keyboard and
// screen-reader semantics for free (WCAG 2.1 AA).
export const Select = React.forwardRef<
  HTMLSelectElement,
  React.SelectHTMLAttributes<HTMLSelectElement>
>(({ className, children, ...props }, ref) => (
  <select
    ref={ref}
    className={cn(
      "h-8 rounded-md border border-input bg-background px-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
      className,
    )}
    {...props}
  >
    {children}
  </select>
));
Select.displayName = "Select";
