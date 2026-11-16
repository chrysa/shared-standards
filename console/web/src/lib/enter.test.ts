import { describe, expect, it } from "vitest";
import { MAX_STAGGERED, enterProps } from "./enter";

describe("enterProps", () => {
  it("marks the element for the entrance animation", () => {
    expect(enterProps().className).toBe("enter");
  });

  it("caps the stagger so a long list still settles quickly", () => {
    const style = (i: number) => (enterProps(i).style as Record<string, number>)["--enter-index"];
    expect(style(0)).toBe(0);
    expect(style(3)).toBe(3);
    expect(style(250)).toBe(MAX_STAGGERED);
    expect(style(-2)).toBe(0);
  });
});
