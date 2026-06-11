import { onCall, HttpsError } from "firebase-functions/v2/https";
import { beforeUserCreated } from "firebase-functions/v2/identity";
import * as admin from "firebase-admin";
import { Type } from "@google/genai";

const { GoogleGenAI } = require("@google/genai");

const GOOGLE_CLOUD_PROJECT = process.env.GCLOUD_PROJECT;
const GOOGLE_CLOUD_LOCATION = "us-east1"; // this is where storage bucket files live too, may have impact on cost but may also not

// Init Firebase Admin SDK
admin.initializeApp();

// white list (stored in firestore config collection)
export const beforecreate = beforeUserCreated(async (event) => {
  const email = event.data?.email;

  const doc = await admin
    .firestore()
    .collection("config")
    .doc("whitelist")
    .get();

  const allowedEmails: string[] = doc.data()?.emails ?? [];

  if (!email || !allowedEmails.includes(email)) {
    throw new HttpsError("permission-denied", "You're not on the white list.");
  }
});

interface AnalyzeMealRequest {
  text?: string;
  imagePath?: string;
  imageMimeType?: string;
  audioPath?: string;
  audioMimeType?: string;
}

/**
 * Helper function to construct a Google Cloud Storage URI
 * for the Gemini SDK (Vertex AI).
 */
function getStorageFileAsPart(storagePath: string, mimeType: string) {
  const bucketName = admin.storage().bucket().name;

  return {
    fileData: {
      fileUri: `gs://${bucketName}/${storagePath}`,
      mimeType: mimeType,
    },
  };
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
      "You are an elite nutritional analysis AI named Snackbert, who is also a cute chipmunk and personal assistant!" +
        "Analyze the provided inputs (text descriptions, meal photos, or spoken audio logs) to estimate the nutritional payload." +
        "Be realistic, encouraging, and provide nutritional values as integers based on common serving guidelines." +
        "When providing nutritional values, be realistic but keep a tendency towards pessimistic guesses if you are unsure about how much calories a meal has. If you have a good guess, keep it. If you are unsure, rather put some calories on top of it for safety sakes." +
        "Your response includes a title that reflects the meal and is at most 25 characters long." +
        "Your response includes an appreciationMessage that is, in the App, said by a cute mascot chipmunk. It's supposed to be only about the meal itself and why it's cool or special or delicious and is not supposed to be longer than 50 characters." +
        "If the image shows a comic chipmunk, ignore it! That's the placeholder image and not intended to be included in your meal analysis." +
        "Make double sure you are encouraging, cute and respond only with a warm attitude towards the user. Avoid commenting eating habits or talking about the amounts eaten." +
        "When creating the appreciationMessage, don't spell out the meal title. Just a short comment about how that is delicious, special or awesome in some way. If you see fit, make the message some kind of wordplay with either the meal itself or with the fact that you are a chipmunk",
      "You only interact with German users so feel free to use German Slang and also properly use their umlauts like ö,ä,ü or ß properly.",
    );

    // TEXT INPUT
    if (data.text && data.text.trim().length > 0) {
      contents.push(`User description: ${data.text}`);
    }

    // IMAGE INPUT
    if (data.imagePath && data.imageMimeType) {
      const imagePart = getStorageFileAsPart(
        data.imagePath,
        data.imageMimeType,
      );
      contents.push(imagePart);
    }

    // AUDIO INPUT
    if (data.audioPath && data.audioMimeType) {
      const audioPart = getStorageFileAsPart(
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
        model: "gemini-2.5-flash",
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
