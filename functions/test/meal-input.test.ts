import { describe, it, expect } from "vitest";
import { buildResearchInput, researchTools } from "../src/meal-input";

const BUCKET = "snackbert-test.appspot.com";

describe("buildResearchInput", () => {
  it("builds an app meal's input exactly as before", () => {
    const meal = {
      inputText: "Linsencurry mit Reis",
      imagePath: "meal_images/m1.jpg",
      imageMimeType: "image/jpeg",
      audioPath: "meal_audios/m1.m4a",
      audioMimeType: "audio/m4a",
    };

    expect(buildResearchInput(meal, BUCKET)).toEqual([
      "User description: Linsencurry mit Reis",
      { fileData: { fileUri: "gs://snackbert-test.appspot.com/meal_images/m1.jpg", mimeType: "image/jpeg" } },
      { fileData: { fileUri: "gs://snackbert-test.appspot.com/meal_audios/m1.m4a", mimeType: "audio/m4a" } },
    ]);
  });

  it("has nothing to analyse for a meal without any input", () => {
    expect(buildResearchInput({ inputText: "  " }, BUCKET)).toEqual([]);
  });

  it("reports a Dish alone as one normal serving, not the whole batch", () => {
    const meal = {
      inputText: "",
      imagePath: null,
      audioPath: null,
      source: "malkochen",
      malkochen: { dish: dish({}) },
    };

    expect(buildResearchInput(meal, BUCKET)).toEqual([
      "Dish from malkochen (what the user cooked):\nTitle: Linsen-Dal",
      "No portion input from the user: count one normal serving of this Dish, not the whole batch the post or a photo may show.",
    ]);
  });

  it("tells where the Dish came from, with the Caption marked as the post's text, maybe for the whole recipe", () => {
    const meal = {
      malkochen: {
        dish: dish({
          sourceUrl: "https://www.tiktok.com/@koch/video/123",
          platform: "TikTok",
          creator: "@koch",
          caption: "Mein Dal mit roten Linsen #vegan",
        }),
      },
    };

    expect(buildResearchInput(meal, BUCKET)).toEqual([
      "Dish from malkochen (what the user cooked):\n" +
        "Title: Linsen-Dal\n" +
        "Source link: https://www.tiktok.com/@koch/video/123\n" +
        "Platform: TikTok\n" +
        "Creator: @koch",
      "Caption of the post (written by the post's author, not by the user; its amounts may be for the whole recipe, not one serving):\n" +
        "Mein Dal mit roten Linsen #vegan",
      "No portion input from the user: count one normal serving of this Dish, not the whole batch the post or a photo may show.",
    ]);
  });

  it("says the post's picture shows the Dish as published, maybe the whole batch, not the portion", () => {
    const meal = {
      malkochen: {
        dish: dish({
          imagePath: "malkochen_dish_images/m2.webp",
          imageMimeType: "image/webp",
          imageKind: "post",
        }),
      },
    };

    expect(buildResearchInput(meal, BUCKET)).toEqual([
      "Dish from malkochen (what the user cooked):\nTitle: Linsen-Dal",
      "The Dish's picture from the post: it shows the Dish as the post published it, maybe the whole batch (a full pot, a tray), not the user's portion.",
      { fileData: { fileUri: "gs://snackbert-test.appspot.com/malkochen_dish_images/m2.webp", mimeType: "image/webp" } },
      "No portion input from the user: count one normal serving of this Dish, not the whole batch the post or a photo may show.",
    ]);
  });

  it("says an Own Photo shows the Dish as the user cooked it, maybe the whole batch", () => {
    const meal = {
      malkochen: {
        dish: dish({
          imagePath: "malkochen_dish_images/m3.jpg",
          imageMimeType: "image/jpeg",
          imageKind: "ownPhoto",
        }),
      },
    };

    expect(buildResearchInput(meal, BUCKET)).toEqual([
      "Dish from malkochen (what the user cooked):\nTitle: Linsen-Dal",
      "The user's own photo of the Dish as they cooked it: it may show the whole batch, not necessarily their portion.",
      { fileData: { fileUri: "gs://snackbert-test.appspot.com/malkochen_dish_images/m3.jpg", mimeType: "image/jpeg" } },
      "No portion input from the user: count one normal serving of this Dish, not the whole batch the post or a photo may show.",
    ]);
  });

  it("puts the user's portion beside the Dish, each portion input labelled", () => {
    const meal = {
      inputText: "Halbe Portion, dazu ein Naan",
      imagePath: "meal_images/m4.jpg",
      imageMimeType: "image/jpeg",
      audioPath: "meal_audios/m4.webm",
      audioMimeType: "audio/webm",
      malkochen: { dish: dish({}) },
    };

    expect(buildResearchInput(meal, BUCKET)).toEqual([
      "Dish from malkochen (what the user cooked):\nTitle: Linsen-Dal",
      "The user's description of their portion: Halbe Portion, dazu ein Naan",
      "The user's photo of their portion:",
      { fileData: { fileUri: "gs://snackbert-test.appspot.com/meal_images/m4.jpg", mimeType: "image/jpeg" } },
      "The user's recording about their portion:",
      { fileData: { fileUri: "gs://snackbert-test.appspot.com/meal_audios/m4.webm", mimeType: "audio/webm" } },
    ]);
  });

  it("counts a photo alone as the portion", () => {
    const meal = {
      imagePath: "meal_images/m5.jpg",
      imageMimeType: "image/jpeg",
      malkochen: { dish: dish({}) },
    };

    expect(buildResearchInput(meal, BUCKET)).toEqual([
      "Dish from malkochen (what the user cooked):\nTitle: Linsen-Dal",
      "The user's photo of their portion:",
      { fileData: { fileUri: "gs://snackbert-test.appspot.com/meal_images/m5.jpg", mimeType: "image/jpeg" } },
    ]);
  });
});

describe("researchTools", () => {
  it("gives an app meal Google Search only, as before", () => {
    expect(researchTools({ inputText: "Pizza" })).toEqual([{ googleSearch: {} }]);
  });

  it("adds URL context when the Dish has a Source link, so the post can be read", () => {
    const meal = { malkochen: { dish: dish({ sourceUrl: "https://www.instagram.com/p/abc/" }) } };
    expect(researchTools(meal)).toEqual([{ googleSearch: {} }, { urlContext: {} }]);
  });

  it("keeps Google Search only for a Dish without a Source link", () => {
    expect(researchTools({ malkochen: { dish: dish({}) } })).toEqual([{ googleSearch: {} }]);
  });
});

function dish(overrides: Record<string, unknown>) {
  return {
    title: "Linsen-Dal",
    sourceUrl: null,
    platform: null,
    creator: null,
    caption: null,
    imagePath: null,
    imageMimeType: null,
    imageKind: null,
    ...overrides,
  };
}
