import { createHandler } from "./interpretation-relay.ts";
import {
  type AIProvider,
  OpenAIProvider,
} from "../supabase/functions/_shared/openai.ts";
import { OpenRouterProvider } from "../supabase/functions/_shared/openrouter.ts";
import { validateInterpretation } from "../supabase/functions/_shared/validation.ts";
import type { Interpretation } from "../supabase/functions/_shared/contracts.ts";
function assert(value: unknown): asserts value {
  if (!value) throw new Error("Assertion failed");
}
const token = "test-only-dev-token-12345678901234567890";
const capture = "11111111-1111-4111-8111-111111111111";
const pageIds = [
  "22222222-2222-4222-8222-222222222222",
  "33333333-3333-4333-8333-333333333333",
];
const images = [1, 2].map((byte) =>
  btoa(String.fromCharCode(255, 216, byte, 255, 217))
);
const summary = {
  what_this_is: "Test",
  what_to_note: "Source-grounded points to note / 原文重点",
  what_to_do: "The letter does not specify what you need to do",
  when: "The letter does not specify a deadline",
  fact_ids: ["date"],
  action_ids: [],
};
const interpretation: Interpretation = {
  schema_version: 1,
  domain: "medical",
  recipient: null,
  organization: null,
  category: null,
  needs_review: true,
  facts: [{
    id: "date",
    kind: "document_date",
    label: { en: "Letter date", zh: "信件日期" },
    explanation: {
      en: "The date this letter was issued",
      zh: "此信的签发日期",
    },
    value: "2026-10-01",
    raw_text: "October 1, 2026",
    currency: null,
    origin: "letter_fact",
    status: "confirmed",
    source_refs: [{ page: 2, excerpt: "October 1, 2026" }],
  }],
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
const request = (path: string, body: unknown) =>
  new Request(`http://127.0.0.1:8787${path}`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });
function setup() {
  let calls = 0;
  let received: string[] = [];
  const provider: AIProvider = {
    interpret: async (image, additional = []) => {
      calls++;
      received = [image, ...additional];
      return structuredClone(interpretation);
    },
  };
  const handler = createHandler(token, provider);
  const accept = async () => images.map((image, index) => ({page_id:pageIds[index],image_base64:image,local_readability:true}));
  return {
    handler,
    accept,
    provider,
    calls: () => calls,
    received: () => received,
  };
}
Deno.test("ordered locally checked pages reach one interpretation; duplicate IDs fail", async () => {
  const test = setup();
  const pages = await test.accept();
  const send = (value: unknown, capture_id = capture) =>
    test.handler(request("/interpret", { capture_id, pages: value }));
  assert((await send([pages[0], pages[0]])).status === 400);
  assert((await send(pages)).status === 200);
  assert(JSON.stringify(test.received()) === JSON.stringify(images));
  assert((await send([...pages].reverse())).status === 200);
  assert(
    JSON.stringify(test.received()) === JSON.stringify([...images].reverse()),
  );
  assert((await send(pages)).status === 200);
  assert(test.calls() === 3);
});
Deno.test("multipage limits and invalid source indices are rejected without truncation", async () => {
  const test = setup();
  assert(
    (await test.handler(
      request("/interpret", { capture_id: capture, pages: [] }),
    )).status === 400,
  );
  assert(
    (await test.handler(
      request("/interpret", { capture_id: capture, pages: Array(11).fill({}) }),
    )).status === 413,
  );
  validateInterpretation(interpretation, 2);
  for (const pageCount of [1, 0, 11]) {
    let failed = false;
    try {
      validateInterpretation(interpretation, pageCount);
    } catch {
      failed = true;
    }
    assert(failed);
  }
  const outside = structuredClone(interpretation);
  outside.facts[0].source_refs[0].page = 3;
  let failed = false;
  try {
    validateInterpretation(outside, 2);
  } catch {
    failed = true;
  }
  assert(failed);
});
Deno.test("failed multipage interpretation allows locally checked pages for an identical retry", async () => {
  const test = setup();
  const pages = await test.accept();
  test.provider.interpret = async () => {
    throw new Error("test failure");
  };
  const body = { capture_id: capture, pages };
  assert((await test.handler(request("/interpret", body))).status === 503);
  test.provider.interpret = async () => interpretation;
  assert((await test.handler(request("/interpret", body))).status === 200);
});
Deno.test("both AI transports send ordered labeled images and page-count-specific source schemas", async () => {
  for (const router of [false, true]) {
    const transport = (async (_url: unknown, init: RequestInit) => {
      const body = JSON.parse(init.body as string);
      const content = router ? body.messages[1].content : body.input[1].content;
      assert(content.length === 4);
      assert(
        content[0].text.startsWith("Page 1 of 2.") &&
          content[2].text.startsWith("Page 2 of 2."),
      );
      // Uploads may be real documents: page labels must not declare them fictional.
      assert(!content[0].text.includes("fictional") && !content[2].text.includes("fictional"));
      const prompt = router ? body.messages[0].content : body.input[0].content;
      assert(!prompt.includes("this fictional test letter"));
      assert(prompt.includes("only when visible source text explicitly establishes that status"));
      const first = router ? content[1].image_url.url : content[1].image_url;
      const second = router ? content[3].image_url.url : content[3].image_url;
      assert(
        first === `data:image/jpeg;base64,${images[0]}` &&
          second === `data:image/jpeg;base64,${images[1]}`,
      );
      const schema = router
        ? body.response_format.json_schema.schema
        : body.text.format.schema;
      assert(
        JSON.stringify(
          schema.properties.facts.items.properties.source_refs.items.properties
            .page.enum,
        ) === "[1,2]",
      );
      return Response.json(
        router
          ? {
            choices: [{
              finish_reason: "stop",
              message: { content: JSON.stringify(interpretation) },
            }],
          }
          : {
            status: "completed",
            output: [{
              content: [{
                type: "output_text",
                text: JSON.stringify(interpretation),
              }],
            }],
          },
      );
    }) as typeof fetch;
    const provider = router
      ? new OpenRouterProvider("fake-key", undefined, transport)
      : new OpenAIProvider("fake-key", undefined, transport);
    assert(
      (await provider.interpret(images[0], [images[1]])).facts[0].source_refs[0]
        .page === 2,
    );
  }
});
Deno.test("retakes after a failed interpretation accept changed bytes with stable or replacement page IDs", async () => {
  for (const stableId of [true, false]) {
    const test = setup();
    const original = await test.accept();
    test.provider.interpret = async () => {
      throw new Error("test failure");
    };
    assert(
      (await test.handler(
        request("/interpret", { capture_id: capture, pages: original }),
      )).status === 503,
    );
    const replacement = {
      page_id: stableId
        ? original[0].page_id
        : "44444444-4444-4444-8444-444444444444",
      image_base64: btoa(String.fromCharCode(255, 216, 3, 255, 217)),
    };
    const selected = { ...replacement, local_readability: true };
    const single = structuredClone(interpretation);
    single.facts[0].source_refs[0].page = 1;
    test.provider.interpret = async () => single;
    // Old locally checked photos can be abandoned; the submitted set is authoritative.
    assert(
      (await test.handler(
        request("/interpret", { capture_id: capture, pages: [selected] }),
      )).status === 200,
    );
    assert(
      (await test.handler(
        request("/interpret", {
          capture_id: capture,
          pages: [{
            ...selected,
            local_readability: false,
          }],
        }),
      )).status === 409,
    );
  }
});
Deno.test("local readability pages need no online validation before one interpretation", async () => {
  let interpretations = 0;
  const handler = createHandler(token, {
    interpret: async () => { interpretations++; return structuredClone(interpretation); },
  });
  const response = await handler(request("/interpret", { capture_id: capture, pages: images.map((image, i) => ({page_id: pageIds[i], image_base64: image, local_readability: true})) }));
  assert(response.status === 200 && interpretations === 1);
});
