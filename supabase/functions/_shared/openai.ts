import {
  type Interpretation,
  interpretationSchemaFor, localizedInterpretationSchemaFor, type OutputLanguage,
} from "./contracts.ts";
import {
  interpretationPrompt, selectedLanguagePrompt,
} from "./prompts.ts";
import {
  SafeError,
  validateInterpretation, validateLocalizedInterpretation,
} from "./validation.ts";
export interface AIProvider {
  interpret(
    image: string,
    additionalImages?: string[],
    language?: OutputLanguage,
  ): Promise<Interpretation>;
}
export interface UsageRecord {
  model: string;
  input_tokens: number | null;
  output_tokens: number | null;
}
// Deliberately allowlist three fields; never forward provider objects to logging.
export function sanitizedUsage(model: string, usage: unknown): UsageRecord {
  const record = usage && typeof usage === "object"
    ? usage as Record<string, unknown>
    : {};
  const tokens = (value: unknown): number | null =>
    typeof value === "number" && Number.isSafeInteger(value) && value >= 0
      ? value
      : null;
  return {
    model: /^[a-zA-Z0-9._:/-]{1,100}$/.test(model) ? model : "unknown",
    input_tokens: tokens(record.input_tokens),
    output_tokens: tokens(record.output_tokens),
  };
}
export class OpenAIProvider implements AIProvider {
  constructor(
    private key: string | undefined,
    private model = "gpt-6-sol",
    private transport: typeof fetch = fetch,
    private recordUsage: (usage: UsageRecord) => void = () => {},
  ) {}
  private async request(
    image: string,
    prompt: string,
    schema: unknown,
    name: string,
    additionalImages: string[] = [],
  ): Promise<unknown> {
    if (!this.key) throw new SafeError("provider_not_configured", 503);
    let response: Response;
    try {
      response = await this.transport("https://api.openai.com/v1/responses", {
        method: "POST",
        signal: AbortSignal.timeout(60000),
        headers: {
          Authorization: `Bearer ${this.key}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: this.model,
          store: false,
          max_output_tokens: 6000,
          input: [{ role: "system", content: prompt }, {
            role: "user",
            content: [image, ...additionalImages].flatMap((page, index) => [{
              type: "input_text",
              text: `Page ${index + 1} of ${
                  additionalImages.length + 1
                }. Read this letter in the supplied page order.`,
            }, {
              type: "input_image",
              image_url: `data:image/jpeg;base64,${page}`,
              detail: "high",
            }]),
          }],
          text: { format: { type: "json_schema", name, strict: true, schema } },
        }),
      });
    } catch {
      throw new SafeError("provider_unavailable", 503);
    }
    if (!response.ok) {
      throw new SafeError(
        response.status === 401
          ? "provider_auth_failed"
          : response.status === 429
          ? "provider_rate_limited"
          : "provider_unavailable",
        503,
      );
    }
    let body: any;
    try {
      body = await response.json();
    } catch {
      throw new SafeError("invalid_ai_output");
    }
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      throw new SafeError("invalid_ai_output");
    }
    // Usage is useful even when generation is incomplete or refused. Missing
    // counters remain null, not a misleading claim of zero token consumption.
    this.recordUsage(sanitizedUsage(this.model, body.usage));
    if (body.status !== "completed" || !Array.isArray(body.output)) {
      throw new SafeError("incomplete_ai_output");
    }
    const content = body.output.flatMap((item: any) =>
      item && Array.isArray(item.content) ? item.content : []
    );
    if (content.some((item: any) => item?.type === "refusal")) {
      throw new SafeError("ai_refusal");
    }
    const parts = content.filter((item: any) => item?.type === "output_text");
    if (parts.length !== 1 || typeof parts[0].text !== "string") {
      throw new SafeError("invalid_ai_output");
    }
    try {
      return JSON.parse(parts[0].text);
    } catch {
      throw new SafeError("invalid_ai_output");
    }
  }
  async interpret(image: string, additionalImages: string[] = [], language?: OutputLanguage) {
    const count = additionalImages.length + 1;
    const value = await this.request(
      image,
      (language ? selectedLanguagePrompt(language) : interpretationPrompt) +
        `\nThe letter contains ${count} ordered pages. Source indices correspond to the explicit Page labels.`,
      language ? localizedInterpretationSchemaFor(count, language) : interpretationSchemaFor(count),
      "letter_interpretation", additionalImages,
    );
    return language ? validateLocalizedInterpretation(value, count, language) : validateInterpretation(value, count);
  }
}
