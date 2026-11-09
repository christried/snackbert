// A request that must be answered with an error status. The handler turns it
// into a JSON response; anything else is an internal error.
export class Rejection extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
  ) {
    super(code);
  }
}

export const badRequest = () => new Rejection(400, "bad_request");
export const payloadTooLarge = () => new Rejection(413, "payload_too_large");
export const unsupportedMediaType = () =>
  new Rejection(415, "unsupported_media_type");
