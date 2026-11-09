import { describe, it, expect } from "vitest";
import { berlinDay, berlinWallClock } from "../src/malkochen/berlin-time";

describe("berlinWallClock", () => {
  it("converts UTC winter time to Berlin (+1)", () => {
    expect(berlinWallClock(new Date("2026-11-09T18:30:00.000Z"))).toBe(
      "2026-11-09T19:30:00.000",
    );
  });

  it("converts UTC summer time to Berlin (+2) and keeps milliseconds", () => {
    expect(berlinWallClock(new Date("2026-07-01T10:00:00.250Z"))).toBe(
      "2026-07-01T12:00:00.250",
    );
  });

  it("handles the DST switch day", () => {
    expect(berlinWallClock(new Date("2026-03-29T01:30:00Z"))).toBe(
      "2026-03-29T03:30:00.000",
    );
  });
});

describe("berlinDay", () => {
  it("uses the Berlin calendar day, not the UTC one", () => {
    expect(berlinDay(new Date("2026-11-09T23:30:00Z"))).toBe("2026-11-10");
  });
});
