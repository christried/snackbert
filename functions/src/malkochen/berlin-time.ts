// The app writes `meals.date` as a local wall-clock ISO string without an
// offset (e.g. "2026-11-09T19:30:00.000"), lists meals by that string and
// filters by its day. Meals from malkochen must match that format, expressed
// in Berlin time, which is where both users live.

const berlinFormatter = new Intl.DateTimeFormat("en-GB", {
  timeZone: "Europe/Berlin",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});

function berlinParts(date: Date): Record<string, string> {
  const parts: Record<string, string> = {};
  for (const part of berlinFormatter.formatToParts(date)) {
    parts[part.type] = part.value;
  }
  return parts;
}

// "YYYY-MM-DDTHH:mm:ss.SSS" in Berlin wall-clock time, no offset.
export function berlinWallClock(date: Date): string {
  const p = berlinParts(date);
  const ms = String(date.getUTCMilliseconds()).padStart(3, "0");
  return `${p.year}-${p.month}-${p.day}T${p.hour}:${p.minute}:${p.second}.${ms}`;
}

// "YYYY-MM-DD" of the Berlin calendar day.
export function berlinDay(date: Date): string {
  const p = berlinParts(date);
  return `${p.year}-${p.month}-${p.day}`;
}
