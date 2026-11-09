import busboy from "busboy";
import { badRequest, payloadTooLarge } from "./errors";

export type FileField = "photo" | "recording" | "dishImage";

export interface UploadedFile {
  bytes: Buffer;
  mimeType: string;
}

export interface MultipartForm {
  report: string;
  files: Partial<Record<FileField, UploadedFile>>;
}

const FILE_FIELDS: readonly string[] = ["photo", "recording", "dishImage"];

function isFileField(name: string): name is FileField {
  return FILE_FIELDS.includes(name);
}

// Busboy's own per-file cap. The per-kind caps are checked by the handler.
const MAX_FILE_BYTES = 10 * 1024 * 1024;

// Parses the multipart body into the `report` JSON and up to three named files.
// Throws Rejection (400 or 413) on anything unexpected.
export function parseMultipart(
  contentType: string,
  body: Buffer,
): Promise<MultipartForm> {
  return new Promise((resolve, reject) => {
    const bb = busboy({
      headers: { "content-type": contentType },
      limits: {
        fileSize: MAX_FILE_BYTES,
        files: 3,
        fields: 1,
        // Busboy emits partsLimit when the Nth part finishes, so 4 (report + 3 files)
        // would fire on every valid request. 5 fires only on a fifth part.
        parts: 5,
        fieldSize: 100 * 1024,
      },
    });

    let report: string | undefined;
    const files: MultipartForm["files"] = {};

    // Reject on the first problem; later events are then ignored by the promise.
    const fail = (error: Error) => reject(error);

    bb.on("field", (name, value, info) => {
      if (name !== "report" || report !== undefined) return fail(badRequest());
      if (info.valueTruncated) return fail(payloadTooLarge());
      report = value;
    });

    bb.on("file", (name, file, info) => {
      // Every stream has to be consumed, or busboy never emits "close".
      if (!isFileField(name) || files[name] !== undefined) {
        file.resume();
        return fail(badRequest());
      }
      const chunks: Buffer[] = [];
      file.on("data", (chunk: Buffer) => chunks.push(chunk));
      file.on("limit", () => fail(payloadTooLarge()));
      file.on("end", () => {
        files[name] = {
          bytes: Buffer.concat(chunks),
          mimeType: info.mimeType,
        };
      });
    });

    bb.on("filesLimit", () => fail(badRequest()));
    bb.on("fieldsLimit", () => fail(badRequest()));
    bb.on("partsLimit", () => fail(badRequest()));
    bb.on("error", () => fail(badRequest()));
    bb.on("close", () => {
      if (report === undefined) return fail(badRequest());
      resolve({ report, files });
    });

    bb.end(body);
  });
}
