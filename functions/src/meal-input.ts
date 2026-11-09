// Builds what the research step reads from a meal document, and which tools it gets.
import type { Tool } from "@google/genai";

// The Dish's details a malkochen Report carries (see malkochen/handler.ts).
export interface MealDish {
  title?: string | null;
  sourceUrl?: string | null;
  platform?: string | null;
  creator?: string | null;
  caption?: string | null;
  imagePath?: string | null;
  imageMimeType?: string | null;
  imageKind?: string | null;
}

// The fields of `meals/<id>` that the research step reads.
export interface MealInput {
  inputText?: string | null;
  imagePath?: string | null;
  imageMimeType?: string | null;
  audioPath?: string | null;
  audioMimeType?: string | null;
  malkochen?: { dish?: MealDish | null } | null;
}

export type ResearchPart =
  | string
  | { fileData: { fileUri: string; mimeType: string } };

function storageFile(bucketName: string, path: string, mimeType: string): ResearchPart {
  return { fileData: { fileUri: `gs://${bucketName}/${path}`, mimeType } };
}

// The user's own input: text, photo, recording. App meals get it exactly as
// they always have; beside a Dish, each part says it's about the portion, so
// the portion photo can't be mistaken for the Dish's image.
function portionParts(meal: MealInput, bucketName: string, besideDish: boolean): ResearchPart[] {
  const parts: ResearchPart[] = [];
  if (meal.inputText?.trim())
    parts.push(
      besideDish
        ? `The user's description of their portion: ${meal.inputText}`
        : `User description: ${meal.inputText}`,
    );
  if (meal.imagePath && meal.imageMimeType) {
    if (besideDish) parts.push("The user's photo of their portion:");
    parts.push(storageFile(bucketName, meal.imagePath, meal.imageMimeType));
  }
  if (meal.audioPath && meal.audioMimeType) {
    if (besideDish) parts.push("The user's recording about their portion:");
    parts.push(storageFile(bucketName, meal.audioPath, meal.audioMimeType));
  }
  return parts;
}

// What the Dish's image shows, by its imageKind. A Map, so a lookup can never hit an Object prototype key.
const DISH_IMAGE_LABELS = new Map([
  [
    "post",
    "The Dish's picture from the post: it shows the Dish as the post published it, maybe the whole batch (a full pot, a tray), not the user's portion.",
  ],
  [
    "ownPhoto",
    "The user's own photo of the Dish as they cooked it: it may show the whole batch, not necessarily their portion.",
  ],
]);

// Only filled-in details appear, one per line.
function dishParts(dish: MealDish, bucketName: string): ResearchPart[] {
  const lines = [
    "Dish from malkochen (what the user cooked):",
    `Title: ${dish.title?.trim()}`,
  ];
  if (dish.sourceUrl?.trim()) lines.push(`Source link: ${dish.sourceUrl.trim()}`);
  if (dish.platform?.trim()) lines.push(`Platform: ${dish.platform.trim()}`);
  if (dish.creator?.trim()) lines.push(`Creator: ${dish.creator.trim()}`);
  const parts: ResearchPart[] = [lines.join("\n")];

  if (dish.caption?.trim())
    parts.push(
      "Caption of the post (written by the post's author, not by the user; its amounts may be for the whole recipe, not one serving):\n" +
        dish.caption.trim(),
    );

  const imageLabel = dish.imageKind ? DISH_IMAGE_LABELS.get(dish.imageKind) : undefined;
  if (imageLabel && dish.imagePath && dish.imageMimeType)
    parts.push(imageLabel, storageFile(bucketName, dish.imagePath, dish.imageMimeType));
  return parts;
}

// The research step's input parts. Empty when the meal has nothing to analyse.
export function buildResearchInput(meal: MealInput, bucketName: string): ResearchPart[] {
  const dish = meal.malkochen?.dish;
  if (!dish?.title?.trim()) return portionParts(meal, bucketName, false);

  const portion = portionParts(meal, bucketName, true);
  const parts = [...dishParts(dish, bucketName), ...portion];
  if (portion.length === 0)
    parts.push("No portion input from the user: count one normal serving of this Dish, never the whole batch.");
  return parts;
}

// Google Search always; URL context too when a Dish's Source link can be read.
export function researchTools(meal: MealInput): Tool[] {
  const tools: Tool[] = [{ googleSearch: {} }];
  if (meal.malkochen?.dish?.sourceUrl?.trim()) tools.push({ urlContext: {} });
  return tools;
}
