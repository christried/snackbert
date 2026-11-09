import * as admin from "firebase-admin";
import { getDownloadURL } from "firebase-admin/storage";
import { randomUUID } from "node:crypto";
import type { MalkochenDeps } from "./handler";

// Real Firebase implementations of the handler's dependencies.
// admin.* is only touched inside the functions, after index.ts has initialised the app.
export function firebaseMalkochenDeps(secrets: string[]): MalkochenDeps {
  return {
    secrets,

    async findUserIdByEmail(email) {
      try {
        const user = await admin.auth().getUserByEmail(email);
        return user.uid;
      } catch (error) {
        if ((error as { code?: string }).code === "auth/user-not-found") return null;
        throw error;
      }
    },

    // One counter document per user and Berlin day, incremented in a transaction
    // so concurrent reports cannot overshoot the limit.
    reserveDailyReport(userId, day, limit) {
      const ref = admin.firestore().collection("malkochenReportCounts").doc(`${userId}_${day}`);
      return admin.firestore().runTransaction(async (tx) => {
        const snapshot = await tx.get(ref);
        const count = (snapshot.data()?.count as number | undefined) ?? 0;
        if (count >= limit) return false;
        tx.set(ref, { userId, day, count: count + 1 });
        return true;
      });
    },

    async storeMedia(path, bytes, contentType) {
      const file = admin.storage().bucket().file(path);
      await file.save(bytes, { contentType, resumable: false });
      return getDownloadURL(file);
    },

    async writeMeal(mealId, meal) {
      await admin.firestore().collection("meals").doc(mealId).set(meal);
    },

    newId: () => randomUUID(),
    now: () => new Date(),
  };
}
