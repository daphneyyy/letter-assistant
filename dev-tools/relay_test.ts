import { allowedHost, createHandler } from "./interpretation-relay.ts";
import {
  type AIProvider,
  OpenAIProvider,
  sanitizedUsage,
  type UsageRecord,
} from "../supabase/functions/_shared/openai.ts";
import { validateInterpretation } from "../supabase/functions/_shared/validation.ts";
import type {
  Action,
  Fact,
  Interpretation,
  Verdict,
} from "../supabase/functions/_shared/contracts.ts";
function assert(value: unknown): asserts value {
  if (!value) throw new Error("Assertion failed");
}
const token = "test-only-token-not-a-real-secret-12345";
const image = btoa(String.fromCharCode(255, 216, 1, 2, 255, 217));
const payload = {
  capture_id: "11111111-1111-4111-8111-111111111111",
  page_id: "22222222-2222-4222-8222-222222222222",
  image_base64: image,
};
const summary = {
  what_this_is: "Test",
  what_to_note: "Source-grounded points to note / 原文重点",
  what_to_do: "The letter does not specify what you need to do",
  when: "The letter does not specify a deadline",
  fact_ids: [],
  action_ids: [],
};
const result: Interpretation = {
  schema_version: 1,
  domain: "medical",
  recipient: null,
  organization: null,
  category: null,
  needs_review: true,
  facts: [],
  actions: [],
  summaries: {
    en: summary,
    zh: {
      ...summary,
      what_this_is: "测试",
      what_to_note: "Source-grounded points to note / 原文重点",
      what_to_do: "信中未说明您需要做什么",
      when: "信中未注明截止日期",
    },
  },
};
// Explicit isolated fake: these tests never establish a successful real AI run.
function fake(verdict: Verdict["verdict"] = "valid"): AIProvider {
  return {
    validate: async () => ({
      verdict,
      reason: { en: "Test reason", zh: "测试原因" },
    }),
    interpret: async () => structuredClone(result),
  };
}
const request = (path: string, body: unknown, auth = token) =>
  new Request(`http://127.0.0.1:8787${path}`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${auth}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });
Deno.test("same accepted bytes required; rejected, changed, expired and other-page images cannot interpret", async () => {
  let clock = 1000;
  const handler = createHandler(token, fake(), () => clock);
  assert((await handler(request("/interpret", payload))).status === 409);
  const validation = await (await handler(request("/validate-page", payload)))
    .json();
  const accepted = {
    ...payload,
    validation_token: validation.validation_token,
  };
  assert((await handler(request("/interpret", accepted))).status === 200);
  assert(
    (await handler(
      request("/interpret", {
        ...accepted,
        image_base64: btoa(String.fromCharCode(255, 216, 3, 255, 217)),
      }),
    )).status === 409,
  );
  assert(
    (await handler(
      request("/interpret", { ...accepted, page_id: payload.capture_id }),
    )).status === 409,
  );
  clock += 16 * 60 * 1000;
  assert((await handler(request("/interpret", accepted))).status === 409);
  for (const verdict of ["retake", "uncertain"] as const) {
    const reject = createHandler(token, fake(verdict));
    const response = await (await reject(request("/validate-page", payload)))
      .json();
    assert(response.validation_token === null);
  }
});
Deno.test("auth, malformed photo, body limits and safe private binding", async () => {
  const handler = createHandler(token, fake());
  assert(
    (await handler(request("/validate-page", payload, "wrong"))).status === 401,
  );
  assert(
    (await handler(
      request("/validate-page", { ...payload, image_base64: "AAAA" }),
    )).status === 400,
  );
  assert(
    (await handler(
      request("/validate-page", {
        ...payload,
        image_base64: "A".repeat(15 * 1024 * 1024),
      }),
    )).status === 413,
  );
  assert(
    allowedHost("192.168.1.12") && allowedHost("127.0.0.1") &&
      !allowedHost("0.0.0.0") && !allowedHost("8.8.8.8"),
  );
});
Deno.test("semantic validation rejects fabricated date, missing evidence, extra categories and wrong references", () => {
  validateInterpretation(result);
  for (
    const mutate of [
      (v: any) => v.category = "needs_review",
      (v: any) =>
        v.facts.push({
          id: "date",
          kind: "deadline",
          label: { en: "Deadline", zh: "截止日期" },
          explanation: { en: "Source-stated cutoff", zh: "信中注明的截止日期" },
          raw_text: "February 30",
          value: "2026-02-30",
          currency: null,
          status: "confirmed",
          origin: "letter_fact",
          source_refs: [{ page: 1, excerpt: "February 30" }],
        }),
      (v: any) =>
        v.facts.push({
          id: "amount",
          kind: "amount",
          label: { en: "Amount", zh: "金额" },
          explanation: { en: "Source-stated amount", zh: "信中注明的金额" },
          raw_text: "12",
          value: "12",
          currency: null,
          status: "confirmed",
          origin: "letter_fact",
          source_refs: [],
        }),
      (v: any) => v.summaries.en.fact_ids.push("invented"),
    ]
  ) {
    const copy = structuredClone(result);
    mutate(copy);
    let rejected = false;
    try {
      validateInterpretation(copy);
    } catch {
      rejected = true;
    }
    assert(rejected);
  }
});
Deno.test("missing provider credential returns honest 503, provider refusals and incomplete output fail safely", async () => {
  const handler = createHandler(token, new OpenAIProvider(undefined));
  const response = await handler(request("/validate-page", payload));
  assert(
    response.status === 503 &&
      (await response.json()).error.code === "provider_not_configured",
  );
  for (
    const body of [{ status: "incomplete", output: [] }, {
      status: "completed",
      output: [{ content: [{ type: "refusal", refusal: "No" }] }],
    }, {
      status: "completed",
      output: [{ content: [{ type: "output_text", text: "{}" }] }],
    }]
  ) {
    const provider = new OpenAIProvider(
      "fake-test-key",
      "test-model",
      (() => Promise.resolve(Response.json(body))) as typeof fetch,
    );
    let rejected = false;
    try {
      await provider.validate(image);
    } catch {
      rejected = true;
    }
    assert(rejected);
  }
});
Deno.test("AI transport sends strict image Responses request without tools, persistence or model fallback", async () => {
  let calls = 0;
  const transport = (async (_url: unknown, options: RequestInit) => {
    calls++;
    const body = JSON.parse(options.body as string);
    assert(
      body.model === "explicit-test-model" && body.store === false &&
        body.tools === undefined,
    );
    assert(
      body.text.format.type === "json_schema" &&
        body.text.format.strict === true,
    );
    assert(
      body.input[1].content[1].image_url === `data:image/jpeg;base64,${image}`,
    );
    return Response.json({
      status: "completed",
      output: [{
        content: [{
          type: "output_text",
          text: JSON.stringify({
            verdict: "valid",
            reason: { en: "Readable", zh: "清晰可读" },
          }),
        }],
      }],
    });
  }) as typeof fetch;
  assert(
    (await new OpenAIProvider("fake-test-key", "explicit-test-model", transport)
      .validate(image)).verdict === "valid",
  );
  assert(calls === 1);
});
Deno.test("failed interpretation can retry against retained acceptance without claiming persistence", async () => {
  let failures = 1;
  const provider = fake();
  provider.interpret = async () => {
    if (failures-- > 0) throw new Error("private internal details");
    return result;
  };
  const handler = createHandler(token, provider);
  const validation = await (await handler(request("/validate-page", payload)))
    .json();
  const accepted = {
    ...payload,
    validation_token: validation.validation_token,
  };
  const failure = await handler(request("/interpret", accepted));
  assert(
    failure.status === 503 && (await failure.text()).includes("request_failed"),
  );
  assert((await handler(request("/interpret", accepted))).status === 200);
});
Deno.test("usage exposes only configured model and valid counters, including refused calls", async () => {
  const usage: UsageRecord[] = [];
  const provider = new OpenAIProvider(
    "fake-test-key",
    "test-model",
    (() =>
      Promise.resolve(Response.json({
        status: "completed",
        model: "provider-controlled text never logged",
        usage: { input_tokens: 321, output_tokens: 17, private_body: "secret" },
        output: [{
          content: [{ type: "refusal", refusal: "private refusal text" }],
        }],
      }))) as typeof fetch,
    (record) => usage.push(record),
  );
  try {
    await provider.validate(image);
  } catch { /* Expected refusal. */ }
  assert(
    JSON.stringify(usage) ===
      JSON.stringify([{
        model: "test-model",
        input_tokens: 321,
        output_tokens: 17,
      }]),
  );
  assert(
    JSON.stringify(
      sanitizedUsage("bad\nmodel", { input_tokens: -1, output_tokens: 2.5 }),
    ) ===
      JSON.stringify({
        model: "unknown",
        input_tokens: null,
        output_tokens: null,
      }),
  );
  assert(sanitizedUsage("test-model", null).input_tokens === null);
});
Deno.test("provider failure responses stay safe and specific through the relay", async () => {
  const cases: [() => Promise<Response>, number, string][] = [
    [
      async () => {
        throw new Error("private network details");
      },
      503,
      "provider_unavailable",
    ],
    [
      async () => new Response("private rate-limit details", { status: 429 }),
      503,
      "provider_rate_limited",
    ],
    [
      async () => new Response("private key error", { status: 401 }),
      503,
      "provider_auth_failed",
    ],
    [async () => new Response("not JSON"), 422, "invalid_ai_output"],
    [async () => Response.json(null), 422, "invalid_ai_output"],
    [
      async () => Response.json({ status: "incomplete", output: [] }),
      422,
      "incomplete_ai_output",
    ],
    [
      async () =>
        Response.json({
          status: "completed",
          output: [{
            content: [{ type: "refusal", refusal: "private refusal text" }],
          }],
        }),
      422,
      "ai_refusal",
    ],
    [
      async () =>
        Response.json({
          status: "completed",
          output: [null, { content: [null] }],
        }),
      422,
      "invalid_ai_output",
    ],
    [
      async () =>
        Response.json({
          status: "completed",
          output: [{ content: [{ type: "output_text", text: "not JSON" }] }],
        }),
      422,
      "invalid_ai_output",
    ],
    [
      async () =>
        Response.json({
          status: "completed",
          output: [{ content: [{ type: "output_text", text: "[]" }] }],
        }),
      422,
      "invalid_ai_output",
    ],
    [
      async () =>
        Response.json({
          status: "completed",
          output: [{
            content: [{
              type: "output_text",
              text: JSON.stringify({ verdict: "valid", reason: [] }),
            }],
          }],
        }),
      422,
      "invalid_ai_output",
    ],
  ];
  for (const [transport, status, code] of cases) {
    const handler = createHandler(
      token,
      new OpenAIProvider(
        "fake-test-key",
        "test-model",
        transport as typeof fetch,
      ),
    );
    const response = await handler(request("/validate-page", payload));
    assert(response.status === status);
    assert(await response.text() === JSON.stringify({ error: { code } }));
  }
});

// Hand-authored contract examples, not model evaluation or canned app results.
const coverageFact: Fact = {
  id: "coverage_start",
  kind: "effective_date",
  raw_text: "Coverage begins January 1, 2027",
  value: "2027-01-01",
  currency: null,
  label: { en: "Coverage starts", zh: "保险生效日期" },
  explanation: {
    en: "The date coverage begins, not a payment deadline",
    zh: "保险开始生效的日期，并非付款截止日期",
  },
  origin: "letter_fact",
  status: "confirmed",
  source_refs: [{ page: 1, excerpt: "Coverage begins January 1, 2027" }],
};
const conditionalAction: Action = {
  id: "correction",
  description_en: "Call to correct your information",
  description_zh: "致电更正您的信息",
  action_kind: "call",
  requirement: "conditional",
  condition: { en: "If your information is incorrect", zh: "如果您的信息有误" },
  status: "confirmed",
  source_refs: [{
    page: 1,
    excerpt: "If your information is incorrect, call us.",
  }],
  amount_fact_ids: [],
  deadline_fact_id: null,
  appointment_fact_ids: [],
};
function enrollmentContract(): Interpretation {
  const value = structuredClone(result);
  value.domain = "insurance";
  value.category = "insurance_explanations";
  value.needs_review = false;
  value.facts = [structuredClone(coverageFact)];
  value.actions = [structuredClone(conditionalAction)];
  value.summaries = {
    en: {
      what_this_is: "Health coverage enrollment confirmation",
      what_to_note: "Source-grounded points to note / 原文重点",
      what_to_do:
        "No required step is stated. Call only if the information is incorrect.",
      when:
        "The effective date is when coverage begins. No deadline is stated.",
      fact_ids: ["coverage_start"],
      action_ids: ["correction"],
    },
    zh: {
      what_this_is: "医疗保险投保确认",
      what_to_note: "Source-grounded points to note / 原文重点",
      what_to_do: "信中未要求必须采取步骤。仅在信息有误时致电。",
      when: "生效日期表示保险开始生效的时间。信中未注明截止日期。",
      fact_ids: ["coverage_start"],
      action_ids: ["correction"],
    },
  };
  return value;
}
Deno.test("enrollment contract preserves effective-date role and conditional steps without inventing deadline", () => {
  const value = validateInterpretation(enrollmentContract());
  assert(value.actions[0].deadline_fact_id === null);
  assert(
    value.facts[0].kind === "effective_date" &&
      value.actions[0].requirement === "conditional",
  );
  const noAction = enrollmentContract();
  noAction.actions = [];
  noAction.summaries.en.action_ids = [];
  noAction.summaries.zh.action_ids = [];
  validateInterpretation(noAction);
  for (const requirement of ["required", "optional"] as const) {
    const alternative = enrollmentContract();
    alternative.actions[0].requirement = requirement;
    alternative.actions[0].condition = null;
    validateInterpretation(alternative);
  }
});
Deno.test("EOB statement and result facts can retain labeled amount, service date and natural reporting period without actions", () => {
  const value = structuredClone(result);
  value.domain = "insurance";
  value.category = "insurance_explanations";
  value.needs_review = false;
  value.facts = [
    {
      ...structuredClone(coverageFact),
      id: "paid",
      kind: "amount",
      value: "120.00",
      currency: "USD",
      raw_text: "Plan paid USD 120.00",
      label: { en: "Insurer paid", zh: "保险公司已支付" },
      explanation: {
        en: "What the plan paid, not a request for you to pay",
        zh: "保险公司已支付的金额，并非要求您付款",
      },
      source_refs: [{ page: 1, excerpt: "Plan paid USD 120.00" }],
    },
    {
      ...structuredClone(coverageFact),
      id: "service",
      kind: "service_date",
      value: "2026-09-12",
      raw_text: "Service date September 12, 2026",
      label: { en: "Service date", zh: "服务日期" },
      explanation: {
        en: "When the care was provided",
        zh: "接受医疗服务的日期",
      },
      source_refs: [{ page: 1, excerpt: "Service date September 12, 2026" }],
    },
    {
      ...structuredClone(coverageFact),
      id: "period",
      kind: "period",
      value: "September 2026",
      raw_text: "Statement period September 2026",
      label: { en: "Statement period", zh: "结算期间" },
      explanation: {
        en: "The period summarized by this statement",
        zh: "此结算单涵盖的期间",
      },
      source_refs: [{ page: 1, excerpt: "Statement period September 2026" }],
    },
  ];
  value.summaries.en.fact_ids = value.facts.map((fact) => fact.id);
  value.summaries.zh.fact_ids = value.facts.map((fact) => fact.id);
  assert(validateInterpretation(value).actions.length === 0);
});
Deno.test("generic interpretation rejects incomplete bilingual roles, invalid dates, wrong references and unsupported facts", () => {
  const mutations: ((value: any) => void)[] = [
    (value) => delete value.facts[0].label,
    (value) => value.facts[0].label.zh = "",
    (value) => value.facts[0].explanation.en = " ",
    (value) => delete value.facts[0].explanation.zh,
    (value) => value.facts[0].value = "2027-02-30",
    (value) => value.actions[0].deadline_fact_id = "coverage_start",
    (value) => value.actions[0].appointment_fact_ids = ["coverage_start"],
    (value) => value.actions[0].amount_fact_ids = ["coverage_start"],
    (value) => value.actions[0].condition = null,
    (value) => value.actions[0].condition.zh = "",
    (value) => {
      value.actions[0].status = "needs_verification";
      value.actions[0].source_refs = [];
    },
    (value) => {
      value.actions[0].requirement = "optional";
    },
    (value) => value.actions[0].requirement = "recommended",
    (value) => value.summaries.zh.fact_ids = [],
    (value) => {
      value.domain = "unsupported";
      value.category = null;
      value.needs_review = true;
      value.actions = [];
    },
  ];
  for (const mutate of mutations) {
    const value = enrollmentContract();
    mutate(value);
    let rejected = false;
    try {
      validateInterpretation(value);
    } catch {
      rejected = true;
    }
    assert(rejected);
  }
  const unsupported = structuredClone(result);
  unsupported.domain = "unsupported";
  validateInterpretation(unsupported);
});
Deno.test("empty in-scope action extraction cannot produce blanket no-action claims", () => {
  const empty = enrollmentContract();
  empty.actions = [];
  empty.summaries.en.action_ids = [];
  empty.summaries.zh.action_ids = [];
  empty.summaries.en.what_to_do = "Nothing needs to be done.";
  empty.summaries.zh.what_to_do = "无需执行任何操作。";
  const checked = validateInterpretation(empty);
  assert(
    checked.summaries.en.what_to_do ===
      "No action steps were identified in the supplied pages.",
  );
  assert(
    checked.summaries.zh.what_to_do ===
      "提供的页面中未识别到办理事项。",
  );
  assert(
    JSON.stringify(checked.summaries.en.fact_ids) === '["coverage_start"]',
  );
  assert(
    JSON.stringify(checked.summaries.zh.fact_ids) === '["coverage_start"]',
  );
  const conditional = enrollmentContract();
  const original = conditional.summaries.en.what_to_do;
  assert(
    validateInterpretation(conditional).summaries.en.what_to_do === original,
  );
  const unsupported = structuredClone(result);
  unsupported.domain = "unsupported";
  unsupported.summaries.en.what_to_do = "Unsupported document";
  assert(
    validateInterpretation(unsupported).summaries.en.what_to_do ===
      "Unsupported document",
  );
});
