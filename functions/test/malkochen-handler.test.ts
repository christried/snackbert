import { describe, it, expect, vi } from "vitest";
import {
  handleMalkochenRequest,
  DAILY_REPORT_LIMIT,
  MalkochenDeps,
  MalkochenRequest,
} from "../src/malkochen/handler";

// In-memory stand-ins for the Firebase dependencies.
function fakeDeps(overrides: { secrets?: string[]; writeMealError?: Error } = {}) {
  const state = {
    accounts: new Map<string, string>([["operator@example.com", "uid-operator"]]),
    counts: new Map<string, number>(),
    media: new Map<string, { bytes: Buffer; contentType: string }>(),
    meals: new Map<string, Record<string, unknown>>(),
    now: new Date("2026-11-09T12:00:00Z"),
  };
  let ids = 0;
  const deps: MalkochenDeps = {
    secrets: overrides.secrets ?? ["prod-secret", "staging-secret"],
    async findUserIdByEmail(email) {
      return state.accounts.get(email) ?? null;
    },
    async reserveDailyReport(userId, day, limit) {
      const key = `${userId}_${day}`;
      const count = state.counts.get(key) ?? 0;
      if (count >= limit) return false;
      state.counts.set(key, count + 1);
      return true;
    },
    async storeMedia(path, bytes, contentType) {
      state.media.set(path, { bytes, contentType });
      return `https://storage.example/${path}`;
    },
    async writeMeal(mealId, meal) {
      if (overrides.writeMealError) throw overrides.writeMealError;
      state.meals.set(mealId, meal);
    },
    newId() {
      ids += 1;
      return `meal-${ids}`;
    },
    now() {
      return state.now;
    },
  };
  return { deps, state };
}

const PROD = "Bearer prod-secret";

function accountRequest(body: unknown, overrides: Partial<MalkochenRequest> = {}): MalkochenRequest {
  return {
    method: "POST",
    path: "/account-check",
    authorization: PROD,
    contentType: "application/json",
    body: Buffer.from(typeof body === "string" ? body : JSON.stringify(body)),
    ...overrides,
  };
}

interface FormFile {
  bytes: Buffer;
  type: string;
}

function baseReport(): Record<string, unknown> {
  return {
    email: "operator@example.com",
    cookedAt: "2026-11-09T18:30:00.000Z",
    dish: { title: "Linsencurry" },
  };
}

// Builds a real multipart body with Node's own FormData. `report: null` omits the report field.
async function reportRequest(
  opts: { report?: string | null; files?: [string, FormFile][]; authorization?: string } = {},
): Promise<MalkochenRequest> {
  const form = new FormData();
  if (opts.report !== null) {
    form.append("report", opts.report ?? JSON.stringify(baseReport()));
  }
  for (const [field, file] of opts.files ?? []) {
    form.append(field, new Blob([new Uint8Array(file.bytes)], { type: file.type }), `${field}.bin`);
  }
  const encoded = new Request("http://localhost/reports", { method: "POST", body: form });
  return {
    method: "POST",
    path: "/reports",
    authorization: opts.authorization ?? PROD,
    contentType: encoded.headers.get("content-type") ?? undefined,
    body: Buffer.from(await encoded.arrayBuffer()),
  };
}

const jpeg = (size = 100): FormFile => ({ bytes: Buffer.alloc(size, 1), type: "image/jpeg" });

describe("auth", () => {
  it("rejects a request without an Authorization header", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(accountRequest({ email: "x" }, { authorization: undefined }), deps);
    expect(res).toEqual({ status: 401, body: { error: "unauthorized" } });
  });

  it("rejects a wrong secret", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(accountRequest({ email: "x" }, { authorization: "Bearer nope" }), deps);
    expect(res).toEqual({ status: 401, body: { error: "unauthorized" } });
  });

  it("rejects an empty token when a configured secret is empty", async () => {
    const { deps } = fakeDeps({ secrets: ["", "prod-secret"] });
    const res = await handleMalkochenRequest(accountRequest({ email: "x" }, { authorization: "Bearer " }), deps);
    expect(res).toEqual({ status: 401, body: { error: "unauthorized" } });
  });

  it("accepts the staging secret", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      accountRequest({ email: "operator@example.com" }, { authorization: "Bearer staging-secret" }),
      deps,
    );
    expect(res).toEqual({ status: 200, body: { exists: true } });
  });

  it("checks auth before routing, so an unknown path without a secret is 401", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      accountRequest({}, { path: "/nope", authorization: undefined }),
      deps,
    );
    expect(res).toEqual({ status: 401, body: { error: "unauthorized" } });
  });
});

describe("routing", () => {
  it("returns 404 for an unknown path with a valid secret", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(accountRequest({}, { path: "/nope" }), deps);
    expect(res).toEqual({ status: 404, body: { error: "not_found" } });
  });

  it("returns 405 for GET /reports", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(accountRequest({}, { method: "GET", path: "/reports" }), deps);
    expect(res).toEqual({ status: 405, body: { error: "method_not_allowed" } });
  });

  it("accepts a trailing slash", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      accountRequest({ email: "operator@example.com" }, { path: "/account-check/" }),
      deps,
    );
    expect(res).toEqual({ status: 200, body: { exists: true } });
  });
});

describe("POST /account-check", () => {
  it("answers exists: true for a known email", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(accountRequest({ email: "operator@example.com" }), deps);
    expect(res).toEqual({ status: 200, body: { exists: true } });
  });

  it("answers exists: false for an unknown email", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(accountRequest({ email: "stranger@example.com" }), deps);
    expect(res).toEqual({ status: 200, body: { exists: false } });
  });

  it("trims the email before looking it up", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(accountRequest({ email: "  operator@example.com  " }), deps);
    expect(res).toEqual({ status: 200, body: { exists: true } });
  });

  it("rejects a non-JSON content type with 415", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      accountRequest({ email: "operator@example.com" }, { contentType: "text/plain" }),
      deps,
    );
    expect(res).toEqual({ status: 415, body: { error: "unsupported_media_type" } });
  });

  it("rejects a missing email with 400", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(accountRequest({}), deps);
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });
});

describe("POST /reports", () => {
  it("accepts a text-only report and writes a pending meal", async () => {
    const { deps, state } = fakeDeps();
    const res = await handleMalkochenRequest(await reportRequest(), deps);

    expect(res).toEqual({ status: 201, body: { mealId: "meal-1" } });
    expect(state.meals.get("meal-1")).toEqual({
      id: "meal-1",
      userId: "uid-operator",
      date: "2026-11-09T19:30:00.000",
      status: "pending",
      inputText: "",
      imagePath: null,
      imageUrl: null,
      imageMimeType: null,
      audioPath: null,
      audioUrl: null,
      audioMimeType: null,
      source: "malkochen",
      malkochen: {
        reportedAt: "2026-11-09T12:00:00.000Z",
        dish: {
          title: "Linsencurry",
          sourceUrl: null,
          platform: null,
          creator: null,
          caption: null,
          imagePath: null,
          imageMimeType: null,
          imageKind: null,
        },
      },
    });
    expect(state.media.size).toBe(0);
  });

  it("stores photo, recording and dish image, and keeps the dish image out of the portion fields", async () => {
    const { deps, state } = fakeDeps();
    const photo = jpeg(50);
    const recording = { bytes: Buffer.from([9, 8, 7]), type: "audio/mp4" };
    const dishImage = { bytes: Buffer.from([4, 5, 6]), type: "image/webp" };
    const report = { ...baseReport(), text: "  mein Anteil  ", dish: { title: " Linsencurry ", imageKind: "post" } };

    const res = await handleMalkochenRequest(
      await reportRequest({
        report: JSON.stringify(report),
        files: [
          ["photo", photo],
          ["recording", recording],
          ["dishImage", dishImage],
        ],
      }),
      deps,
    );

    expect(res).toEqual({ status: 201, body: { mealId: "meal-1" } });
    expect(state.media.get("meal_images/meal-1.jpg")).toEqual({ bytes: photo.bytes, contentType: "image/jpeg" });
    expect(state.media.get("meal_audios/meal-1.m4a")).toEqual({ bytes: recording.bytes, contentType: "audio/mp4" });
    expect(state.media.get("malkochen_dish_images/meal-1.webp")).toEqual({
      bytes: dishImage.bytes,
      contentType: "image/webp",
    });

    const meal = state.meals.get("meal-1")!;
    expect(meal).toMatchObject({
      inputText: "mein Anteil",
      imagePath: "meal_images/meal-1.jpg",
      imageUrl: "https://storage.example/meal_images/meal-1.jpg",
      imageMimeType: "image/jpeg",
      audioPath: "meal_audios/meal-1.m4a",
      audioUrl: "https://storage.example/meal_audios/meal-1.m4a",
      audioMimeType: "audio/mp4",
      malkochen: {
        dish: {
          title: "Linsencurry",
          imagePath: "malkochen_dish_images/meal-1.webp",
          imageMimeType: "image/webp",
          imageKind: "post",
        },
      },
    });
  });

  it("stores a dish image alone without touching the portion photo fields", async () => {
    const { deps, state } = fakeDeps();
    const report = { ...baseReport(), dish: { title: "Linsencurry", imageKind: "ownPhoto" } };

    const res = await handleMalkochenRequest(
      await reportRequest({
        report: JSON.stringify(report),
        files: [["dishImage", { bytes: Buffer.from([1]), type: "image/png" }]],
      }),
      deps,
    );

    expect(res.status).toBe(201);
    expect(state.media.has("malkochen_dish_images/meal-1.png")).toBe(true);
    expect(state.media.has("meal_images/meal-1.jpg")).toBe(false);
    const meal = state.meals.get("meal-1")!;
    expect(meal.imagePath).toBeNull();
    expect(meal.imageUrl).toBeNull();
    expect(meal.imageMimeType).toBeNull();
    expect(meal.malkochen).toMatchObject({
      dish: { imagePath: "malkochen_dish_images/meal-1.png", imageMimeType: "image/png", imageKind: "ownPhoto" },
    });
  });

  it("accepts audio/webm with codecs and stores it as audio/webm", async () => {
    const { deps, state } = fakeDeps();
    const res = await handleMalkochenRequest(
      await reportRequest({
        files: [["recording", { bytes: Buffer.from([1]), type: "audio/webm;codecs=opus" }]],
      }),
      deps,
    );

    expect(res.status).toBe(201);
    expect(state.media.get("meal_audios/meal-1.webm")?.contentType).toBe("audio/webm");
    expect(state.meals.get("meal-1")).toMatchObject({
      audioPath: "meal_audios/meal-1.webm",
      audioMimeType: "audio/webm",
    });
  });

  it("returns 404 no_account and writes nothing, stores nothing and takes no count", async () => {
    const { deps, state } = fakeDeps();
    const report = { ...baseReport(), email: "stranger@example.com" };
    const res = await handleMalkochenRequest(
      await reportRequest({ report: JSON.stringify(report), files: [["photo", jpeg()]] }),
      deps,
    );

    expect(res).toEqual({ status: 404, body: { error: "no_account" } });
    expect(state.meals.size).toBe(0);
    expect(state.media.size).toBe(0);
    expect(state.counts.size).toBe(0);
  });

  it("allows 20 reports a day, refuses the 21st, and resets on the next Berlin day", async () => {
    const { deps, state } = fakeDeps();
    expect(DAILY_REPORT_LIMIT).toBe(20);

    for (let i = 1; i <= DAILY_REPORT_LIMIT; i++) {
      const res = await handleMalkochenRequest(await reportRequest(), deps);
      expect(res).toEqual({ status: 201, body: { mealId: `meal-${i}` } });
    }

    const refused = await handleMalkochenRequest(await reportRequest({ files: [["photo", jpeg()]] }), deps);
    expect(refused).toEqual({ status: 429, body: { error: "daily_limit" } });
    expect(state.meals.size).toBe(DAILY_REPORT_LIMIT);
    expect(state.media.size).toBe(0);

    state.now = new Date("2026-11-10T12:00:00Z");
    const nextDay = await handleMalkochenRequest(await reportRequest(), deps);
    expect(nextDay.status).toBe(201);
  });

  it("returns 413 for text over 1000 characters", async () => {
    const { deps } = fakeDeps();
    const report = { ...baseReport(), text: "a".repeat(1001) };
    const res = await handleMalkochenRequest(await reportRequest({ report: JSON.stringify(report) }), deps);
    expect(res).toEqual({ status: 413, body: { error: "payload_too_large" } });
  });

  it("accepts text of exactly 1000 characters", async () => {
    const { deps } = fakeDeps();
    const report = { ...baseReport(), text: "a".repeat(1000) };
    const res = await handleMalkochenRequest(await reportRequest({ report: JSON.stringify(report) }), deps);
    expect(res.status).toBe(201);
  });

  it("returns 413 for a photo of 3 MB plus one byte", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      await reportRequest({ files: [["photo", jpeg(3 * 1024 * 1024 + 1)]] }),
      deps,
    );
    expect(res).toEqual({ status: 413, body: { error: "payload_too_large" } });
  });

  it("returns 413 for a caption over 10000 characters", async () => {
    const { deps } = fakeDeps();
    const report = { ...baseReport(), dish: { title: "Linsencurry", caption: "c".repeat(10001) } };
    const res = await handleMalkochenRequest(await reportRequest({ report: JSON.stringify(report) }), deps);
    expect(res).toEqual({ status: 413, body: { error: "payload_too_large" } });
  });

  it("returns 415 for a photo that is not image/jpeg", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      await reportRequest({ files: [["photo", { bytes: Buffer.from([1]), type: "image/png" }]] }),
      deps,
    );
    expect(res).toEqual({ status: 415, body: { error: "unsupported_media_type" } });
  });

  it("returns 415 for a recording that is video/mp4", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      await reportRequest({ files: [["recording", { bytes: Buffer.from([1]), type: "video/mp4" }]] }),
      deps,
    );
    expect(res).toEqual({ status: 415, body: { error: "unsupported_media_type" } });
  });

  it("returns 415 for a dish image that is image/gif", async () => {
    const { deps } = fakeDeps();
    const report = { ...baseReport(), dish: { title: "Linsencurry", imageKind: "post" } };
    const res = await handleMalkochenRequest(
      await reportRequest({
        report: JSON.stringify(report),
        files: [["dishImage", { bytes: Buffer.from([1]), type: "image/gif" }]],
      }),
      deps,
    );
    expect(res).toEqual({ status: 415, body: { error: "unsupported_media_type" } });
  });

  it("returns 415 for a non-multipart content type", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      { ...(await reportRequest()), contentType: "application/json" },
      deps,
    );
    expect(res).toEqual({ status: 415, body: { error: "unsupported_media_type" } });
  });

  it("returns 400 when cookedAt is missing", async () => {
    const { deps } = fakeDeps();
    const { cookedAt: _omitted, ...report } = baseReport();
    const res = await handleMalkochenRequest(await reportRequest({ report: JSON.stringify(report) }), deps);
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("returns 400 when cookedAt is not a date", async () => {
    const { deps } = fakeDeps();
    const report = { ...baseReport(), cookedAt: "yesterday" };
    const res = await handleMalkochenRequest(await reportRequest({ report: JSON.stringify(report) }), deps);
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("returns 400 when the report is not JSON", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(await reportRequest({ report: "not json" }), deps);
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("returns 400 when a dish image comes without imageKind", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      await reportRequest({ files: [["dishImage", { bytes: Buffer.from([1]), type: "image/jpeg" }]] }),
      deps,
    );
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("returns 400 when imageKind is given without a dish image", async () => {
    const { deps } = fakeDeps();
    const report = { ...baseReport(), dish: { title: "Linsencurry", imageKind: "post" } };
    const res = await handleMalkochenRequest(await reportRequest({ report: JSON.stringify(report) }), deps);
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("returns 400 for an unknown file field", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      await reportRequest({ files: [["video", { bytes: Buffer.from([1]), type: "video/mp4" }]] }),
      deps,
    );
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("returns 400 when the report field is missing", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(await reportRequest({ report: null, files: [["photo", jpeg()]] }), deps);
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("returns 400 for a body that is not multipart at all", async () => {
    const { deps } = fakeDeps();
    const res = await handleMalkochenRequest(
      { ...(await reportRequest()), body: Buffer.from("garbage") },
      deps,
    );
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("returns 400 for an empty dish title", async () => {
    const { deps } = fakeDeps();
    const report = { ...baseReport(), dish: { title: "   " } };
    const res = await handleMalkochenRequest(await reportRequest({ report: JSON.stringify(report) }), deps);
    expect(res).toEqual({ status: 400, body: { error: "bad_request" } });
  });

  it("stores whitespace-only text as an empty inputText", async () => {
    const { deps, state } = fakeDeps();
    const report = { ...baseReport(), text: "   \n  " };
    const res = await handleMalkochenRequest(await reportRequest({ report: JSON.stringify(report) }), deps);
    expect(res.status).toBe(201);
    expect(state.meals.get("meal-1")?.inputText).toBe("");
  });

  it("returns 500 internal when writing the meal fails", async () => {
    const spy = vi.spyOn(console, "error").mockImplementation(() => {});
    const { deps } = fakeDeps({ writeMealError: new Error("firestore down") });
    const res = await handleMalkochenRequest(await reportRequest(), deps);
    expect(res).toEqual({ status: 500, body: { error: "internal" } });
    expect(spy).toHaveBeenCalledWith("malkochen handler error:", "firestore down");
    spy.mockRestore();
  });
});
