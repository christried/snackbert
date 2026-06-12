import { HttpsError } from "firebase-functions/v2/https";
import { beforeUserCreated } from "firebase-functions/v2/identity";
import * as admin from "firebase-admin";
import { Type } from "@google/genai";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

const { GoogleGenAI } = require("@google/genai");

const snackbertSystemPrompt = `You are Snackbert, an elite nutritional analysis AI, personal assistant, and a cute mascot chipmunk! 
Your job is to analyze the user's inputs (text, audio, and/or image) and evaluate the meal.

### NUTRITIONAL ANALYSIS RULES:
1. COMPREHENSIVE SCAN: Analyze all provided inputs together (image, text, and audio). Leave no detail out.
2. THE USER IS GOSPEL: If the user explicitly states a calorie amount, ingredient weight, or specific brand in their text or audio, you MUST use their exact numbers and estimate only the rest.
3. MACROS FIRST: Always estimate the exact total Carbs, Proteins, and Fats (in grams) first. Base this on credible sources (USDA, Cronometer, or explicit brand data).
4. STRICT CALORIE MATH: The \`calories\` output MUST perfectly match your macro estimates. Calculate calories strictly as: (carbs * 4) + (proteins * 4) + (fats * 9).
5. PESSIMISTIC ESTIMATION: If you are unsure about portions or ingredients, pick the 85th percentile (higher end) of the likely calorie/macro range for safety. If you are highly confident, just be accurate.
6. CONFLICTING INPUTS: If the user provides sensible text or audio (e.g., "I ate an apple"), but the attached image is completely unrelated (e.g., a steering wheel), completely ignore the image and base your analysis ONLY on the text/audio.
7. NOT FOOD (NONSENSE INPUT): If the inputs describe or show something that is clearly not food and cannot be eaten (e.g., a shoe, a car, a laptop), output exactly 0 for calories, carbs, fats, and proteins.

### PERSONA & OUTPUT RULES:
1. LANGUAGE: German only. Use conversational phrasing, German slang, and proper umlauts (ä, ö, ü, ß).
2. ATTITUDE: Warm, encouraging, and cute. NEVER judge eating habits or comment negatively on the quantity of food eaten.
3. TITLE: Provide a short, descriptive German title (max 25 characters).
4. APPRECIATION MESSAGE: A cute comment (max 50 characters). Focus on why the meal is delicious or special. Do NOT repeat the title. Chipmunk/nut-related wordplay is highly encouraged!
5. THE NONSENSE JOKE: If Analysis Rule 7 (NOT FOOD) is triggered, use the title and appreciationMessage to make a funny, lightly mocking joke about how you definitely cannot eat that object.`;

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

// New function to call GenAI and to replace the other one completely once nobody is calling that one anymore.
export const processPendingMeal = onDocumentCreated(
  "meals/{mealId}",
  async (event) => {
    const data = event.data?.data();
    // ignores already-processed docs
    if (!data || data.status !== "pending") return;

    const mealId = event.params.mealId;
    const mealRef = admin.firestore().collection("meals").doc(mealId);

    try {
      const aiClient = new GoogleGenAI({
        vertexai: true,
        project: GOOGLE_CLOUD_PROJECT,
        location: GOOGLE_CLOUD_LOCATION,
      });

      const contents: any[] = [];
      if (data.inputText?.trim())
        contents.push(`User description: ${data.inputText}`);
      if (data.imagePath && data.imageMimeType)
        contents.push(getStorageFileAsPart(data.imagePath, data.imageMimeType));
      if (data.audioPath && data.audioMimeType)
        contents.push(getStorageFileAsPart(data.audioPath, data.audioMimeType));

      if (contents.length === 0) {
        await mealRef.update({
          status: "error",
          errorMessage: "No input provided.",
        });
        return;
      }

      const response = await aiClient.models.generateContent({
        model: "gemini-2.5-flash",
        contents,
        config: {
          systemInstruction: snackbertSystemPrompt,
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
                  "Total estimated calories (kcal) based on the strict formula: (carbs*4) + (proteins*4) + (fats*9).",
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

      const result = JSON.parse(response.text);

      await mealRef.update({
        status: "done",
        title: result.title,
        appreciationMessage: result.appreciationMessage,
        calories: result.calories,
        macros: {
          carb: result.carbs,
          protein: result.proteins,
          fat: result.fats,
        },
      });
    } catch (error) {
      console.error("processPendingMeal error:", error);
      await mealRef.update({
        status: "error",
        errorMessage: (error as Error).message,
      });
    }
  },
);
