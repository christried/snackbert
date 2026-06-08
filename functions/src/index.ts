import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { Type } from "@google/genai";

const { GoogleGenAI } = require("@google/genai");

const GOOGLE_CLOUD_PROJECT = process.env.GCLOUD_PROJECT;
const GOOGLE_CLOUD_LOCATION = "global";

// Init Firebase Admin SDK
admin.initializeApp();

interface AnalyzeMealRequest {
  text?: string;
  imagePath?: string;
  imageMimeType?: string;
  audioPath?: string;
  audioMimeType?: string;
}

/**
 * Helper function to download a file from Firebase Storage
 * and convert it into an inline data object for the Gemini SDK.
 */
async function getStorageFileAsPart(storagePath: string, mimeType: string) {
  try {
    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);

    const [fileBuffer] = await file.download();

    return {
      inlineData: {
        data: fileBuffer.toString("base64"),
        mimeType: mimeType,
      },
    };
  } catch (error) {
    throw new HttpsError(
      "internal",
      `Failed to fetch file from Storage path: ${storagePath}. Error: ${(error as Error).message}`,
    );
  }
}

export const analyzeMealData = onCall(
  {
    secrets: ["GEMINI_API_KEY"], // not really used anymore but I set it up so I'll just have it here if I move back from Vertex AI SDK to direct API calls
    maxInstances: 5, // rateLimiter, may be adjusted if we pass this to more than Mara + Me
  },
  async (request) => {
    // Ensure user is authenticated
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const data = request.data as AnalyzeMealRequest;
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Gemini API key is missing on the server configuration.",
      );
    }

    // Init AI SDK
    const aiClient = new GoogleGenAI({
      vertexai: true,
      project: GOOGLE_CLOUD_PROJECT,
      location: GOOGLE_CLOUD_LOCATION,
    });

    const contents: any[] = [];

    // Add System Instruction / Core Prompt rules
    contents.push(
      "You are an elite nutritional analysis AI named Snackbert. " +
        "Analyze the provided inputs (text descriptions, meal photos, or spoken audio logs) to estimate the nutritional payload. " +
        "Be realistic, encouraging, and provide nutritional values as integers based on common serving guidelines.",
    );

    // TEXT INPUT
    if (data.text && data.text.trim().length > 0) {
      contents.push(`User description: ${data.text}`);
    }

    // IMAGE INPUT
    if (data.imagePath && data.imageMimeType) {
      const imagePart = await getStorageFileAsPart(
        data.imagePath,
        data.imageMimeType,
      );
      contents.push(imagePart);
    }

    // AUDIO INPUT
    if (data.audioPath && data.audioMimeType) {
      const audioPart = await getStorageFileAsPart(
        data.audioPath,
        data.audioMimeType,
      );
      contents.push(audioPart);
    }

    // Sanity Check for missing user input
    if (contents.length === 1) {
      throw new HttpsError(
        "invalid-argument",
        "Provide at least text description, an image, or an audio track.",
      );
    }

    try {
      const response = await aiClient.models.generateContent({
        model: "gemini-3.5-flash",
        contents: contents,
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              title: {
                type: Type.STRING,
                description:
                  "A short descriptive title for the meal in German language.",
              },
              appreciationMessage: {
                type: Type.STRING,
                description:
                  "A friendly, conversational appreciation message/feedback about the meal in German language.",
              },
              calories: {
                type: Type.INTEGER,
                description:
                  "Total estimated calories (kcal) as a strict integer value.",
              },
              carbs: {
                type: Type.INTEGER,
                description:
                  "Total carbohydrate count in grams as a strict integer value.",
              },
              fats: {
                type: Type.INTEGER,
                description:
                  "Total fat count in grams as a strict integer value.",
              },
              proteins: {
                type: Type.INTEGER,
                description:
                  "Total protein count in grams as a strict integer value.",
              },
            },
            required: [
              "title",
              "appreciationMessage",
              "calories",
              "carbs",
              "fats",
              "proteins",
            ],
          },
        },
      });

      const resultText = response.text;
      if (!resultText) {
        throw new HttpsError(
          "internal",
          "Received an empty evaluation from Gemini.",
        );
      }

      // Doc says responseSchema is strict and cant fail so we just parse and hope I guess
      return JSON.parse(resultText);
    } catch (error) {
      console.error("Gemini API error:", error);
      throw new HttpsError(
        "internal",
        `Gemini API failed: ${(error as Error).message}`,
      );
    }
  },
);
