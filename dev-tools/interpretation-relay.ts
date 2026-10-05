// Development only: fictional letters on a trusted private network. No persistence.
import {
  type AIProvider,
  OpenAIProvider,
  type UsageRecord,
} from "../supabase/functions/_shared/openai.ts";
import {
  FREE_MODEL,
  OpenRouterProvider,
} from "../supabase/functions/_shared/openrouter.ts";
import {
  SafeError,
  validateInterpretation,
} from "../supabase/functions/_shared/validation.ts";
const MAX_IMAGE = 10 * 1024 * 1024;
const MAX_BODY = Math.ceil(MAX_IMAGE / 3) * 4 + 2048;
const MAX_PAGES = 10;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export function configuredProvider(
  env: (key: string) => string | undefined,
  transport: typeof fetch = fetch,
  recordUsage: (usage: UsageRecord) => void = () => {},
): AIProvider {
  // Explicit unified settings take precedence; never borrow a different provider's key.
  if (env("AI_API_KEY") !== undefined || env("AI_MODEL") !== undefined || env("AI_BASE_URL") !== undefined) {
    const flag = env("AI_FREE_ONLY") ?? "true";
    if (flag !== "true" && flag !== "false") throw new Error("AI_FREE_ONLY must be true or false");
    return new OpenRouterProvider(
      env("AI_API_KEY"), env("AI_MODEL") ?? FREE_MODEL, transport, recordUsage,
      { baseURL: env("AI_BASE_URL"), freeOnly: flag === "true" },
    );
  }
  // An explicitly configured OpenRouter key never falls back to paid OpenAI,
  // even if the key is empty/invalid or the free endpoint is unavailable.
  if (env("OPENROUTER_API_KEY") !== undefined) {
    return new OpenRouterProvider(
      env("OPENROUTER_API_KEY"),
      env("OPENROUTER_MODEL") ?? FREE_MODEL,
      transport,
      recordUsage,
    );
  }
  return new OpenAIProvider(
    env("OPENAI_API_KEY"),
    env("OPENAI_MODEL") ?? "gpt-6-sol",
    transport,
    recordUsage,
  );
}
const json = (value: unknown, status = 200) =>
  Response.json(value, {
    status,
    headers: {
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
    },
  });
export function allowedHost(host: string): boolean {
  if (["localhost", "127.0.0.1", "::1"].includes(host)) return true;
  if (!/^\d{1,3}(\.\d{1,3}){3}$/.test(host)) return false;
  const parts = host.split(".").map(Number);
  return parts.length === 4 &&
    parts.every((n) => Number.isInteger(n) && n >= 0 && n <= 255) &&
    (parts[0] === 10 || (parts[0] === 192 && parts[1] === 168) ||
      (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31));
}
async function readPayload(
  request: Request,
  maxBody = MAX_BODY,
): Promise<Record<string, unknown>> {
  if (!request.headers.get("content-type")?.startsWith("application/json")) {
    throw new SafeError("invalid_request", 400);
  }
  const reader = request.body?.getReader();
  if (!reader) throw new SafeError("invalid_request", 400);
  const chunks: Uint8Array[] = [];
  let length = 0;
  let timedOut = false;
  const timer = setTimeout(() => { timedOut = true; void reader.cancel(); }, 60000);
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (timedOut) throw new SafeError("upload_timeout", 408);
      if (done) break;
      length += value.length;
      if (length > maxBody) {
        await reader.cancel();
        throw new SafeError("photo_too_large", 413);
      }
      chunks.push(value);
    }
  } finally {
    clearTimeout(timer);
    reader.releaseLock();
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  try {
    const value = JSON.parse(
      new TextDecoder("utf-8", { fatal: true }).decode(bytes),
    );
    if (!value || typeof value !== "object" || Array.isArray(value)) {
      throw new Error();
    }
    return value;
  } catch {
    throw new SafeError("invalid_request", 400);
  }
}
async function checkImage(image: string): Promise<void> {
  if (image.length > Math.ceil(MAX_IMAGE / 3) * 4) {
    throw new SafeError("photo_too_large", 413);
  }
  if (
    !image ||
    !/^[A-Za-z0-9+/]+={0,2}$/.test(image)
  ) throw new SafeError("invalid_photo", 400);
  let bytes: Uint8Array;
  try {
    bytes = Uint8Array.from(atob(image), (c) => c.charCodeAt(0));
  } catch {
    throw new SafeError("invalid_photo", 400);
  }
  if (bytes.length > MAX_IMAGE) throw new SafeError("photo_too_large", 413);
  // JPEG framing only; readability is checked locally by the phone.
  if (
    bytes.length < 4 || bytes[0] !== 255 || bytes[1] !== 216 ||
    bytes.at(-2) !== 255 || bytes.at(-1) !== 217
  ) throw new SafeError("invalid_photo", 400);
}
export function createHandler(
  token: string,
  provider: AIProvider,
  now = Date.now,
) {
  if (token.length < 32) {
    throw new Error("DEV_ACCESS_TOKEN must contain at least 32 characters.");
  }
  let active = false;
  let calls: number[] = [];
  return async (request: Request): Promise<Response> => {
    let ownsSlot = false;
    try {
      if (request.headers.get("authorization") !== `Bearer ${token}`) {
        throw new SafeError("unauthorized", 401);
      }
      if (request.headers.has("origin")) {
        throw new SafeError("invalid_request", 403);
      }
      const path = new URL(request.url).pathname;
      if (
        request.method !== "POST" ||
        path !== "/interpret"
      ) throw new SafeError("not_found", 404);
      if (active) throw new SafeError("busy", 429);
      calls = calls.filter((t) => t > now() - 60000);
      if (calls.length >= 12) throw new SafeError("rate_limited", 429);
      calls.push(now());
      active = true;
      ownsSlot = true;
      const body = await readPayload(
        request,
        MAX_BODY * MAX_PAGES,
      );
      const allowed = ["capture_id", "pages", "language"];
      if (Object.keys(body).some(k => !allowed.includes(k)) ||
          typeof body.capture_id !== "string" || !UUID.test(body.capture_id) ||
          (body.language !== undefined && body.language !== "en" && body.language !== "zh")) {
        throw new SafeError("invalid_request", 400);
      }
      const pages = body.pages;
      if (!Array.isArray(pages) || pages.length === 0) {
        throw new SafeError("invalid_request", 400);
      }
      if (pages.length > MAX_PAGES) {
        throw new SafeError("page_limit_exceeded", 413);
      }
      const ids = new Set<string>();
      const images: string[] = [];
      for (const page of pages) {
        if (
          !page || typeof page !== "object" || Array.isArray(page) ||
          Object.keys(page).some((k) =>
            !["page_id", "image_base64", "local_readability"].includes(k)
          ) || typeof page.page_id !== "string" || !UUID.test(page.page_id) ||
          typeof page.image_base64 !== "string" || ids.has(page.page_id)
        ) throw new SafeError("invalid_request", 400);
        ids.add(page.page_id);
        await checkImage(page.image_base64);
        // This flag records the user's local readability decision, not AI attestation.
        if (page.local_readability !== true) throw new SafeError("local_readability_required", 409);
        images.push(page.image_base64);
      }
      // The submitted ordered set is the user's completeness declaration.
      // Local checks may belong to legitimate discarded/retaken photos.
      // These local bytes are fixed for this request; a later request can submit
      // locally checked replacements without being locked to an old attempt.
      return json(
        validateInterpretation(
          await provider.interpret(images[0], images.slice(1), body.language === "zh" ? "zh" : "en"),
          images.length,
        ),
      );
    } catch (error) {
      const safe = error instanceof SafeError
        ? error
        : new SafeError("request_failed", 503);
      console.warn(JSON.stringify({event: "relay_error", code: safe.code, status: safe.status}));
      return json({ error: { code: safe.code } }, safe.status);
    } finally {
      if (ownsSlot) active = false;
    }
  };
}
if (import.meta.main) {
  const host = Deno.env.get("RELAY_HOST") ?? "127.0.0.1";
  if (!allowedHost(host)) {
    throw new Error(
      "RELAY_HOST must be loopback or an explicit private IPv4 address; wildcard/public binding is refused.",
    );
  }
  const port = Number(Deno.env.get("RELAY_PORT") ?? "8787");
  if (!Number.isInteger(port) || port < 1024 || port > 65535) {
    throw new Error("Invalid RELAY_PORT.");
  }
  const handler = createHandler(
    Deno.env.get("DEV_ACCESS_TOKEN") ?? "",
    configuredProvider(
      (key) => Deno.env.get(key),
      fetch,
      (usage) => console.log(JSON.stringify(usage)),
    ),
  );
  Deno.serve({
    hostname: host,
    port,
    onListen: () =>
      console.log(
        "Fictional-letter development relay ready. No archive storage. Use trusted private networking only.",
      ),
  }, handler);
}
