import { configuredProvider, createHandler } from "./interpretation-relay.ts";
import {
  FREE_MODEL,
  OpenRouterProvider,
} from "../supabase/functions/_shared/openrouter.ts";
import type { UsageRecord } from "../supabase/functions/_shared/openai.ts";
function assert(value: unknown): asserts value {
  if (!value) throw new Error("Assertion failed");
}
const token = "test-only-dev-token-12345678901234567890";
const image = btoa(String.fromCharCode(255, 216, 1, 255, 217));
const payload = {
  capture_id: "11111111-1111-4111-8111-111111111111",
  page_id: "22222222-2222-4222-8222-222222222222",
  image_base64: image,
};
const request = () =>
  new Request("http://127.0.0.1:8787/validate-page", {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });
const verdict = {
  verdict: "valid",
  reason: { en: "Readable", zh: "清晰可读" },
};
const completion = (
  content: unknown = JSON.stringify(verdict),
  finish = "stop",
) => ({
  choices: [{ finish_reason: finish, message: { content } }],
  usage: {
    prompt_tokens: 123,
    completion_tokens: 45,
    private_content: "never log",
  },
});

Deno.test("OpenRouter pins free model, zero prices, strict image JSON request and sanitized usage", async () => {
  const usages: UsageRecord[] = [];
  let calls = 0;
  const transport = (async (url: string | URL | Request, init: RequestInit) => {
    calls++;
    assert(url === "https://openrouter.ai/api/v1/chat/completions");
    const body = JSON.parse(init.body as string);
    assert(
      body.model === FREE_MODEL && body.models === undefined &&
        body.tools === undefined,
    );
    assert(
      body.stream === false && body.response_format.type === "json_schema" &&
        body.response_format.json_schema.strict === true,
    );
    assert(
      body.provider.allow_fallbacks === false &&
        body.provider.require_parameters === true,
    );
    assert(
      Object.values(body.provider.max_price).every((price) => price === 0),
    );
    assert(Object.keys(body.provider.max_price).length === 4);
    assert(body.reasoning.enabled === false);
    assert(body.messages[0].content.includes(JSON.stringify(body.response_format.json_schema.schema)));
    assert(
      body.messages[1].content[1].image_url.url ===
        `data:image/jpeg;base64,${image}`,
    );
    return Response.json(completion());
  }) as typeof fetch;
  const provider = new OpenRouterProvider(
    "fake-test-key",
    undefined,
    transport,
    (usage) => usages.push(usage),
  );
  assert((await provider.validate(image)).verdict === "valid" && calls === 1);
  assert(
    JSON.stringify(usages) ===
      JSON.stringify([{
        model: FREE_MODEL,
        input_tokens: 123,
        output_tokens: 45,
      }]),
  );
});

Deno.test("OpenRouter selection never retries on OpenAI and refuses nonfree models before transport", async () => {
  let calls = 0;
  const transport = (async () => {
    calls++;
    return new Response("private upstream error", { status: 503 });
  }) as typeof fetch;
  const env = {
    OPENROUTER_API_KEY: "fake-router-key",
    OPENAI_API_KEY: "fake-openai-key",
  } as Record<string, string>;
  const selected = configuredProvider((key) => env[key], transport);
  assert(selected instanceof OpenRouterProvider);
  assert(
    (await createHandler(token, selected)(request())).status === 503 &&
      calls === 1,
  );
  for (
    const model of [
      "paid/model",
      "paid/model:free:extended",
      "openrouter/free",
      "provider/model:free\n",
    ]
  ) {
    const response = await createHandler(
      token,
      new OpenRouterProvider("fake-key", model, transport),
    )(request());
    assert(
      response.status === 503 &&
        (await response.json()).error.code === (model.includes("\n") ? "invalid_provider_configuration" : "free_model_required"),
    );
  }
  assert(calls === 1);
  env.OPENROUTER_API_KEY = "";
  const empty = await createHandler(
    token,
    configuredProvider((key) => env[key], transport),
  )(request());
  assert(
    (await empty.json()).error.code === "provider_not_configured" &&
      calls === 1,
  );
});

Deno.test("OpenRouter refusal, truncation, malformed and failures return safe errors without response leakage", async () => {
  const cases: [() => Promise<Response>, string, number][] = [
    [
      async () => {
        throw new Error("private failure");
      },
      "provider_unavailable",
      503,
    ],
    [
      async () => new Response("private key error", { status: 401 }),
      "provider_auth_failed",
      503,
    ],
    [
      async () => new Response("private quota", { status: 429 }),
      "provider_rate_limited",
      503,
    ],
    [
      async () => new Response("private endpoint unavailable", { status: 404 }),
      "provider_unavailable",
      503,
    ],
    [async () => new Response("not json"), "invalid_ai_output", 422],
    [async () => Response.json(null), "invalid_ai_output", 422],
    [
      async () => Response.json({ error: { message: "private" } }),
      "provider_unavailable",
      503,
    ],
    [
      async () => Response.json(completion(JSON.stringify(verdict), "length")),
      "incomplete_ai_output",
      422,
    ],
    [
      async () =>
        Response.json(completion(JSON.stringify(verdict), "content_filter")),
      "ai_refusal",
      422,
    ],
    [
      async () =>
        Response.json({
          choices: [{
            finish_reason: "stop",
            message: { refusal: "private refusal" },
          }],
        }),
      "ai_refusal",
      422,
    ],
    [
      async () => Response.json(completion("not json")),
      "invalid_ai_output",
      422,
    ],
    [async () => Response.json(completion("{}")), "invalid_ai_output", 422],
    [async () => Response.json(completion(null)), "invalid_ai_output", 422],
    [async () => Response.json({ choices: [null] }), "invalid_ai_output", 422],
    [async () => Response.json({ choices: [] }), "invalid_ai_output", 422],
  ];
  for (const [transport, code, status] of cases) {
    const handler = createHandler(
      token,
      new OpenRouterProvider("fake-key", undefined, transport as typeof fetch),
    );
    const response = await handler(request());
    assert(response.status === status);
    assert(await response.text() === JSON.stringify({ error: { code } }));
  }
});

Deno.test("unified configuration switches endpoint model and key without router-only fields or fallback", async () => {
  let calls = 0;
  const env: Record<string, string> = {
    AI_BASE_URL: "https://example.test/v1/", AI_MODEL: "vision-model",
    AI_API_KEY: "test-new-key", AI_FREE_ONLY: "false", OPENROUTER_API_KEY: "old-unused-key",
  };
  const transport = (async (url: unknown, init: RequestInit) => {
    calls++;
    assert(url === "https://example.test/v1/chat/completions");
    assert((init.headers as Record<string, string>).Authorization === "Bearer test-new-key");
    assert(init.redirect === "error");
    const body = JSON.parse(init.body as string);
    assert(body.model === "vision-model" && !body.provider && !body.reasoning);
    assert(body.response_format.json_schema.strict);
    return Response.json(completion());
  }) as typeof fetch;
  assert((await configuredProvider(k => env[k], transport).validate(image)).verdict === "valid");
  env.AI_API_KEY = "";
  const missing = await createHandler(token, configuredProvider(k => env[k], transport))(request());
  assert((await missing.json()).error.code === "provider_not_configured" && calls === 1);
  env.AI_API_KEY = "test-new-key";
  env.AI_BASE_URL = "http://example.test/v1";
  const insecure = await createHandler(token, configuredProvider(k => env[k], transport))(request());
  assert((await insecure.json()).error.code === "invalid_provider_configuration" && calls === 1);
});
Deno.test("explicit paid OpenRouter selection removes only the free-price restriction", async () => {
  const env: Record<string, string> = { AI_MODEL: "vendor/paid-model", AI_API_KEY: "test-key", AI_FREE_ONLY: "false" };
  const transport = (async (_url: unknown, init: RequestInit) => {
    const body = JSON.parse(init.body as string);
    assert(body.model === "vendor/paid-model" && body.provider.max_price === undefined);
    assert(body.provider.allow_fallbacks === false);
    return Response.json(completion());
  }) as typeof fetch;
  assert((await configuredProvider(k => env[k], transport).validate(image)).verdict === "valid");
});
