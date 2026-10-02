import { interpretationSchemaFor, verdictSchema } from "./contracts.ts";
import { type AIProvider, sanitizedUsage, type UsageRecord } from "./openai.ts";
import {
  interpretationPrompt,
  validationImageLabel,
  validationPrompt,
} from "./prompts.ts";
import {
  SafeError,
  validateInterpretation,
  validateVerdict,
} from "./validation.ts";

export const FREE_MODEL = "dots-studio/dots-3-note-preview:free";

// Explicit free model plus zero-price routing. No automatic model/provider retry.
export class OpenRouterProvider implements AIProvider {
  constructor(
    private key: string | undefined,
    private model = FREE_MODEL,
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
    if (!/^[a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+:free$/.test(this.model)) {
      throw new SafeError("free_model_required", 503);
    }
    if (!this.key) throw new SafeError("provider_not_configured", 503);
    let response: Response;
    try {
      response = await this.transport(
        "https://openrouter.ai/api/v1/chat/completions",
        {
          method: "POST",
          signal: AbortSignal.timeout(60000),
          headers: {
            Authorization: `Bearer ${this.key}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: this.model,
            stream: false,
            max_tokens: 6000,
            reasoning: { enabled: false },
            provider: {
              require_parameters: true,
              allow_fallbacks: false,
              max_price: { prompt: 0, completion: 0, request: 0, image: 0 },
            },
            messages: [
              {
                role: "system",
                content: `${prompt}\nReturn only JSON matching this schema: ${
                  JSON.stringify(schema)
                }`,
              },
              {
                role: "user",
                content: [image, ...additionalImages].flatMap((page, index) => [
                  {
                    type: "text",
                    text: name === "page_validation"
                      ? validationImageLabel
                      : `Page ${index + 1} of ${
                        additionalImages.length + 1
                      }. Read this fictional letter in the supplied page order.`,
                  },
                  {
                    type: "image_url",
                    image_url: { url: `data:image/jpeg;base64,${page}` },
                  },
                ]),
              },
            ],
            response_format: {
              type: "json_schema",
              json_schema: { name, strict: true, schema },
            },
          }),
        },
      );
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
    this.recordUsage(
      sanitizedUsage(this.model, {
        input_tokens: body.usage?.prompt_tokens,
        output_tokens: body.usage?.completion_tokens,
      }),
    );
    if (body.error) throw new SafeError("provider_unavailable", 503);
    if (!Array.isArray(body.choices) || body.choices.length !== 1) {
      throw new SafeError("invalid_ai_output");
    }
    const choice = body.choices[0];
    if (!choice || typeof choice !== "object") {
      throw new SafeError("invalid_ai_output");
    }
    if (choice.finish_reason === "content_filter" || choice.message?.refusal) {
      throw new SafeError("ai_refusal");
    }
    if (choice.finish_reason !== "stop") {
      throw new SafeError("incomplete_ai_output");
    }
    if (typeof choice.message?.content !== "string") {
      throw new SafeError("invalid_ai_output");
    }
    try {
      return JSON.parse(choice.message.content);
    } catch {
      throw new SafeError("invalid_ai_output");
    }
  }

  async validate(image: string) {
    return validateVerdict(
      await this.request(
        image,
        validationPrompt,
        verdictSchema,
        "page_validation",
      ),
    );
  }

  async interpret(image: string, additionalImages: string[] = []) {
    return validateInterpretation(
      await this.request(
        image,
        interpretationPrompt +
          `\nThe letter contains ${
            additionalImages.length + 1
          } ordered pages. Source indices correspond to the explicit Page labels.`,
        interpretationSchemaFor(additionalImages.length + 1),
        "letter_interpretation",
        additionalImages,
      ),
      additionalImages.length + 1,
    );
  }
}
