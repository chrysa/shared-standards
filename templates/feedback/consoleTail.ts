// Ring buffer of the most recent console.error / console.warn lines, attached
// once at startup. Bug reports include this tail so a backend issue carries the
// client-side errors the user saw. Capped to keep the payload (and memory) small.
//
// Canonical source: chrysa/shared-standards/templates/feedback/consoleTail.ts

const MAX_LINES = 50;
const buffer: string[] = [];
let installed = false;

function stringify(value: unknown): string {
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

function record(level: string, args: unknown[]): void {
  buffer.push(`[${level}] ${args.map(stringify).join(" ")}`);
  if (buffer.length > MAX_LINES) buffer.shift();
}

/** Patch console.error/warn to tee into the ring buffer. Idempotent. */
export function installConsoleTail(): void {
  if (installed) return;
  installed = true;
  (["error", "warn"] as const).forEach((level) => {
    const original = console[level].bind(console);
    console[level] = (...args: unknown[]) => {
      record(level, args);
      original(...args);
    };
  });
}

/** Snapshot of the captured console lines, oldest first. */
export function getConsoleTail(): string[] {
  return [...buffer];
}
