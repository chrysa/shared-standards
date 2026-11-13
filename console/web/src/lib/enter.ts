import type { CSSProperties } from "react";

/** Only the first items stagger: a group settles within the 400 ms FE-053 budget. */
export const MAX_STAGGERED = 5;

/**
 * Props for a basic content entrance (FE-053): `className="enter"` plus the stagger index.
 * The animation runs once, when the element mounts; keep stable keys so refetched rows are
 * not re-mounted and do not replay it.
 */
export function enterProps(index = 0): { className: string; style: CSSProperties } {
  const capped = Math.min(Math.max(index, 0), MAX_STAGGERED);
  return { className: "enter", style: { "--enter-index": capped } as CSSProperties };
}
