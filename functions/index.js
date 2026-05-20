const fs = require("fs");
const os = require("os");
const path = require("path");

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const OpenAI = require("openai");

const openAiKey = defineSecret("OPENAI_API_KEY");

exports.analyzeMeal = onCall(
  {
    timeoutSeconds: 60,
    memory: "512MiB",
    secrets: [openAiKey],
    enforceAppCheck: false,
  },
  async (request) => {
    const data = request.data ?? {};

    if (data.text != null && typeof data.text !== "string") {
      throw new HttpsError("invalid-argument", "text must be a string.");
    }
    if (data.imageUrl != null && typeof data.imageUrl !== "string") {
      throw new HttpsError("invalid-argument", "imageUrl must be a string.");
    }
    if (data.audioUrl != null && typeof data.audioUrl !== "string") {
      throw new HttpsError("invalid-argument", "audioUrl must be a string.");
    }

    const text = normalizeOptionalString(data.text);
    const imageUrl = normalizeOptionalString(data.imageUrl);
    const audioUrl = normalizeOptionalString(data.audioUrl);

    if (!text && !imageUrl && !audioUrl) {
      throw new HttpsError(
        "invalid-argument",
        "Provide at least one of text, imageUrl, or audioUrl.",
      );
    }

    const openai = new OpenAI({ apiKey: openAiKey.value() });

    let transcript = null;
    if (audioUrl) {
      const audioPath = await downloadToTempFile(audioUrl, "audio");
      try {
        const transcription = await openai.audio.transcriptions.create({
          model: "whisper-1",
          file: fs.createReadStream(audioPath),
        });
        transcript = normalizeOptionalString(transcription.text);
      } finally {
        await fs.promises.unlink(audioPath).catch(() => {});
      }
    }

    const promptLines = [
      "Estimate nutrition for the meal based on the provided input.",
      "Return JSON with integer values for calories (kcal), carbs (g), fats (g), proteins (g).",
    ];

    if (text) {
      promptLines.push(`User text: ${text}`);
    }
    if (transcript) {
      promptLines.push(`User audio transcription: ${transcript}`);
    }

    const userContent = [
      {
        type: "text",
        text: promptLines.join("\n"),
      },
    ];

    if (imageUrl) {
      userContent.push({
        type: "image_url",
        image_url: {
          url: imageUrl,
        },
      });
    }

    let completion;
    try {
      completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content:
              "You are a nutrition assistant. Respond only with JSON containing calories, carbs, fats, proteins.",
          },
          {
            role: "user",
            content: userContent,
          },
        ],
        response_format: { type: "json_object" },
      });
    } catch (error) {
      logger.error("OpenAI request failed", error);
      throw new HttpsError("internal", "OpenAI request failed.");
    }

    const content = completion?.choices?.[0]?.message?.content;
    if (!content) {
      throw new HttpsError("internal", "OpenAI returned no content.");
    }

    let parsed;
    try {
      parsed = JSON.parse(content);
    } catch (error) {
      logger.error("Failed to parse OpenAI JSON", error);
      throw new HttpsError("internal", "OpenAI returned invalid JSON.");
    }

    const calories = requireNumber(parsed, "calories");
    const carbs = requireNumber(parsed, "carbs");
    const fats = requireNumber(parsed, "fats");
    const proteins = requireNumber(parsed, "proteins");

    return {
      calories: Math.round(calories),
      carbs: Math.round(carbs),
      fats: Math.round(fats),
      proteins: Math.round(proteins),
    };
  },
);

function normalizeOptionalString(value) {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function requireNumber(source, key) {
  if (source == null || typeof source !== "object") {
    throw new HttpsError("internal", "OpenAI returned invalid JSON.");
  }
  const value = source[key];
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  throw new HttpsError("internal", `OpenAI returned invalid ${key}.`);
}

async function downloadToTempFile(url, label) {
  let response;
  try {
    response = await fetch(url);
  } catch (error) {
    logger.error("Failed to fetch media", error);
    throw new HttpsError("invalid-argument", "Unable to fetch media file.");
  }

  if (!response.ok) {
    throw new HttpsError("invalid-argument", "Unable to fetch media file.");
  }

  const buffer = Buffer.from(await response.arrayBuffer());
  const tempPath = path.join(os.tmpdir(), `${label}-${Date.now()}.bin`);
  await fs.promises.writeFile(tempPath, buffer);
  return tempPath;
}
