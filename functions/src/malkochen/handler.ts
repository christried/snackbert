import { createHash, timingSafeEqual } from "node:crypto";
import { berlinDay, berlinWallClock } from "./berlin-time";
import {
  badRequest,
  payloadTooLarge,
  Rejection,
  unsupportedMediaType,
} from "./errors";
import { parseMultipart, UploadedFile } from "./multipart";

export interface MalkochenRequest {
  method: string;
  path: string; // e.g. "/account-check", "/reports"
  authorization?: string; // raw Authorization header
  contentType?: string; // raw Content-Type header
  body: Buffer; // raw body bytes
}

export interface MalkochenResponse {
  status: number;
  body: Record<string, unknown>;
}

export interface MalkochenDeps {
  secrets: string[]; // accepted caller secrets (production, staging); empty strings never match
  findUserIdByEmail(email: string): Promise<string | null>;
  reserveDailyReport(userId: string, day: string, limit: number): Promise<boolean>; // false = limit reached; true = one slot taken
  storeMedia(path: string, bytes: Buffer, contentType: string): Promise<string>; // returns a download URL
  writeMeal(mealId: string, meal: Record<string, unknown>): Promise<void>;
  newId(): string;
  now(): Date;
}

export const DAILY_REPORT_LIMIT = 20;

const MB = 1024 * 1024;
const PHOTO_MAX_BYTES = 3 * MB;
const MEDIA_MAX_BYTES = 5 * MB;

// Maps of media type, so a lookup can never hit an Object prototype key.
const RECORDING_TYPES = new Map([
  ["audio/mp4", { mimeType: "audio/mp4", ext: "m4a" }],
  ["audio/m4a", { mimeType: "audio/m4a", ext: "m4a" }],
  ["audio/x-m4a", { mimeType: "audio/m4a", ext: "m4a" }],
  ["audio/webm", { mimeType: "audio/webm", ext: "webm" }],
  ["audio/mpeg", { mimeType: "audio/mpeg", ext: "mp3" }],
  ["audio/wav", { mimeType: "audio/wav", ext: "wav" }],
]);

const DISH_IMAGE_EXTS = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"],
]);

interface StoredFile {
  bytes: Buffer;
  mimeType: string;
  ext: string;
}

// The part of a Content-Type before any parameters, lowercased and trimmed.
function mediaType(header: string | undefined): string {
  return (header ?? "").split(";")[0].trim().toLowerCase();
}

function errorResponse(status: number, code: string): MalkochenResponse {
  return { status, body: { error: code } };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// Checks the Bearer token against every configured secret, comparing
// fixed-length digests in constant time. Empty secrets never match.
function isAuthorized(authorization: string | undefined, secrets: string[]): boolean {
  const match = /^Bearer (\S+)$/.exec(authorization ?? "");
  if (!match) return false;
  const tokenDigest = createHash("sha256").update(match[1]).digest();
  let ok = false;
  for (const secret of secrets) {
    if (secret === "") continue;
    const secretDigest = createHash("sha256").update(secret).digest();
    if (timingSafeEqual(tokenDigest, secretDigest)) ok = true;
  }
  return ok;
}

// Counts characters, not UTF-16 code units, so an emoji counts as one.
function charLength(value: string): number {
  return [...value].length;
}

async function handleAccountCheck(
  req: MalkochenRequest,
  deps: MalkochenDeps,
): Promise<MalkochenResponse> {
  if (mediaType(req.contentType) !== "application/json") throw unsupportedMediaType();

  let parsed: unknown;
  try {
    parsed = JSON.parse(req.body.toString("utf8"));
  } catch {
    throw badRequest();
  }
  const email = isRecord(parsed) ? parsed.email : undefined;
  if (typeof email !== "string" || email.trim() === "") throw badRequest();

  const userId = await deps.findUserIdByEmail(email.trim());
  return { status: 200, body: { exists: userId !== null } };
}

// What the Dish's image shows: the picture from the post, or a photo of the cooked Dish.
type ImageKind = "post" | "ownPhoto";

interface ReportDish {
  title: string;
  sourceUrl: string | null;
  platform: string | null;
  creator: string | null;
  caption: string | null;
  imageKind: ImageKind | null;
}

// Already trimmed where it matters.
interface ReportBody {
  email: string;
  cookedAt: Date;
  text: string;
  dish: ReportDish;
}

// Optional string field: absent or null is fine, a wrong type is a bad request,
// and a value over `max` characters is too large.
function optionalString(value: unknown, max: number): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "string") throw badRequest();
  if (charLength(value) > max) throw payloadTooLarge();
  return value;
}

// Checks the report's JSON shape and limits. imageKind is required exactly
// when a dish image is sent, and must be absent otherwise.
function parseReport(raw: string, hasDishImage: boolean): ReportBody {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw badRequest();
  }
  if (!isRecord(parsed)) throw badRequest();

  const { email, cookedAt, dish } = parsed;
  if (typeof email !== "string" || email.trim() === "") throw badRequest();
  // The time needs its offset ("Z" or "+01:00"); without one it would be read as the server's time zone.
  if (
    typeof cookedAt !== "string" ||
    !/(Z|[+-]\d{2}:\d{2})$/i.test(cookedAt) ||
    Number.isNaN(new Date(cookedAt).getTime())
  ) {
    throw badRequest();
  }
  if (!isRecord(dish)) throw badRequest();

  const text = optionalString(parsed.text, 1000) ?? "";

  if (typeof dish.title !== "string" || dish.title.trim() === "") throw badRequest();
  if (charLength(dish.title) > 300) throw payloadTooLarge();

  let imageKind: ImageKind | null = null;
  if (dish.imageKind === "post" || dish.imageKind === "ownPhoto") {
    imageKind = dish.imageKind;
  } else if (dish.imageKind !== undefined && dish.imageKind !== null) {
    throw badRequest();
  }
  if ((imageKind !== null) !== hasDishImage) throw badRequest();

  return {
    email: email.trim(),
    cookedAt: new Date(cookedAt),
    text: text.trim(),
    dish: {
      title: dish.title.trim(),
      sourceUrl: optionalString(dish.sourceUrl, 2000),
      platform: optionalString(dish.platform, 2000),
      creator: optionalString(dish.creator, 2000),
      caption: optionalString(dish.caption, 10000),
      imageKind,
    },
  };
}

// An empty file is a bad request, one over `max` bytes too large.
function checkSize(file: UploadedFile, max: number): void {
  if (file.bytes.length === 0) throw badRequest();
  if (file.bytes.length > max) throw payloadTooLarge();
}

// Photo: only image/jpeg, up to 3 MB.
function checkPhoto(file: UploadedFile): StoredFile {
  if (mediaType(file.mimeType) !== "image/jpeg") throw unsupportedMediaType();
  checkSize(file, PHOTO_MAX_BYTES);
  return { bytes: file.bytes, mimeType: "image/jpeg", ext: "jpg" };
}

// Recording: an allowed audio type, mapped to its stored type and extension.
function checkRecording(file: UploadedFile): StoredFile {
  const allowed = RECORDING_TYPES.get(mediaType(file.mimeType));
  if (!allowed) throw unsupportedMediaType();
  checkSize(file, MEDIA_MAX_BYTES);
  return { bytes: file.bytes, ...allowed };
}

// Dish image: jpeg, png or webp, up to 5 MB.
function checkDishImage(file: UploadedFile): StoredFile {
  const type = mediaType(file.mimeType);
  const ext = DISH_IMAGE_EXTS.get(type);
  if (!ext) throw unsupportedMediaType();
  checkSize(file, MEDIA_MAX_BYTES);
  return { bytes: file.bytes, mimeType: type, ext };
}

async function handleReport(
  req: MalkochenRequest,
  deps: MalkochenDeps,
): Promise<MalkochenResponse> {
  if (mediaType(req.contentType) !== "multipart/form-data") throw unsupportedMediaType();

  const form = await parseMultipart(req.contentType ?? "", req.body);
  const { photo, recording, dishImage } = form.files;
  const report = parseReport(form.report, dishImage !== undefined);

  // Every file is validated before any dependency is called.
  const photoFile = photo ? checkPhoto(photo) : null;
  const recordingFile = recording ? checkRecording(recording) : null;
  const dishImageFile = dishImage ? checkDishImage(dishImage) : null;

  const userId = await deps.findUserIdByEmail(report.email);
  if (userId === null) return errorResponse(404, "no_account");

  // Take the daily slot before storing anything, so a refusal stores nothing.
  // A store or write that fails afterwards still spends the slot: the limit
  // guards the Vertex bill, so erring on the strict side is fine.
  const now = deps.now();
  const reserved = await deps.reserveDailyReport(userId, berlinDay(now), DAILY_REPORT_LIMIT);
  if (!reserved) return errorResponse(429, "daily_limit");

  const mealId = deps.newId();

  // Stores a file at its path and answers where it went; nothing when there is no file.
  const store = async (folder: string, file: StoredFile | null) => {
    if (!file) return null;
    const path = `${folder}/${mealId}.${file.ext}`;
    const url = await deps.storeMedia(path, file.bytes, file.mimeType);
    return { path, url, mimeType: file.mimeType };
  };
  const photoStored = await store("meal_images", photoFile);
  const recordingStored = await store("meal_audios", recordingFile);
  // The Dish's image is kept apart from the portion photo, which is all the app shows.
  const dishImageStored = await store("malkochen_dish_images", dishImageFile);

  const { dish } = report;
  await deps.writeMeal(mealId, {
    id: mealId,
    userId,
    date: berlinWallClock(report.cookedAt),
    status: "pending",
    inputText: report.text,
    imagePath: photoStored?.path ?? null,
    imageUrl: photoStored?.url ?? null,
    imageMimeType: photoStored?.mimeType ?? null,
    audioPath: recordingStored?.path ?? null,
    audioUrl: recordingStored?.url ?? null,
    audioMimeType: recordingStored?.mimeType ?? null,
    source: "malkochen",
    malkochen: {
      reportedAt: now.toISOString(),
      dish: {
        title: dish.title,
        sourceUrl: dish.sourceUrl,
        platform: dish.platform,
        creator: dish.creator,
        caption: dish.caption,
        imagePath: dishImageStored?.path ?? null,
        imageMimeType: dishImageStored?.mimeType ?? null,
        imageKind: dish.imageKind,
      },
    },
  });

  return { status: 201, body: { mealId } };
}

async function route(req: MalkochenRequest, deps: MalkochenDeps): Promise<MalkochenResponse> {
  // Authentication comes before routing, so unknown paths need a secret too.
  if (!isAuthorized(req.authorization, deps.secrets)) return errorResponse(401, "unauthorized");

  // One trailing slash is accepted.
  const path = req.path.length > 1 && req.path.endsWith("/") ? req.path.slice(0, -1) : req.path;

  let handler: (req: MalkochenRequest, deps: MalkochenDeps) => Promise<MalkochenResponse>;
  if (path === "/account-check") handler = handleAccountCheck;
  else if (path === "/reports") handler = handleReport;
  else return errorResponse(404, "not_found");

  if (req.method !== "POST") return errorResponse(405, "method_not_allowed");
  return handler(req, deps);
}

export async function handleMalkochenRequest(
  req: MalkochenRequest,
  deps: MalkochenDeps,
): Promise<MalkochenResponse> {
  try {
    return await route(req, deps);
  } catch (caught) {
    if (caught instanceof Rejection) return errorResponse(caught.status, caught.code);
    // Log only the message: request bodies can contain personal data.
    console.error("malkochen handler error:", (caught as Error).message);
    return errorResponse(500, "internal");
  }
}
