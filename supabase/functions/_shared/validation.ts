import {
  type Interpretation,
  interpretationSchemaFor,
  type Verdict,
  verdictSchema,
} from "./contracts.ts";
export class SafeError extends Error {
  constructor(public code: string, public status = 422) {
    super(code);
  }
}
// Validate provider output again locally; structured output is not a trust boundary.
export function matchesSchema(value: unknown, schema: any): boolean {
  if (schema.enum && !schema.enum.includes(value)) return false;
  const types = Array.isArray(schema.type) ? schema.type : [schema.type];
  if (value === null) return types.includes("null");
  if (
    types.includes("object") && typeof value === "object" &&
    !Array.isArray(value)
  ) {
    const record = value as Record<string, unknown>;
    return Object.keys(record).every((k) =>
      Object.hasOwn(schema.properties, k)
    ) &&
      schema.required.every((k: string) =>
        Object.hasOwn(record, k) &&
        matchesSchema(record[k], schema.properties[k])
      );
  }
  if (types.includes("array") && Array.isArray(value)) {
    return value.length <= 100 &&
      value.every((v) => matchesSchema(v, schema.items));
  }
  if (types.includes("string") && typeof value === "string") {
    return value.length <= 8000;
  }
  if (types.includes("integer")) return Number.isInteger(value);
  return typeof value === "boolean" && types.includes("boolean");
}
export function validateVerdict(value: unknown): Verdict {
  if (!matchesSchema(value, verdictSchema)) {
    throw new SafeError("invalid_ai_output");
  }
  const result = value as Verdict;
  if (!result.reason.en.trim() || !result.reason.zh.trim()) {
    throw new SafeError("invalid_ai_output");
  }
  return result;
}
export function validateInterpretation(
  value: unknown,
  pageCount = 1,
): Interpretation {
  const fail = () => {
    throw new SafeError("invalid_ai_output");
  };
  if (!Number.isInteger(pageCount) || pageCount < 1 || pageCount > 10) fail();
  if (!matchesSchema(value, interpretationSchemaFor(pageCount))) fail();
  const result = value as Interpretation;
  if (result.needs_review !== (result.category === null)) fail();
  if (
    result.domain === "unsupported" &&
    (result.category !== null || result.actions.length || result.facts.length)
  ) fail();
  const ids = [...result.facts, ...result.actions].map((v) => v.id);
  if (ids.some((id) => !id.trim()) || new Set(ids).size !== ids.length) fail();
  for (const item of [...result.facts, ...result.actions]) {
    if (
      item.source_refs.some((s) =>
        s.page < 1 || s.page > pageCount || !s.excerpt.trim()
      )
    ) fail();
    if (item.status === "confirmed" && item.source_refs.length === 0) fail();
  }
  for (const fact of result.facts) {
    if (
      ![fact.label.en, fact.label.zh, fact.explanation.en, fact.explanation.zh]
        .every((text) => text.trim())
    ) fail();
    if (fact.status === "not_specified" && fact.value !== null) fail();
    if (
      fact.status === "confirmed" &&
      (!fact.value?.trim() || !fact.raw_text.trim())
    ) fail();
    if (
      fact.kind === "amount" && fact.value !== null &&
      !/^-?\d+(\.\d+)?$/.test(fact.value)
    ) fail();
    if (
      [
        "document_date",
        "deadline",
        "appointment_date",
        "effective_date",
        "service_date",
      ].includes(fact.kind) &&
      fact.value !== null
    ) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(fact.value)) fail();
      const date = new Date(fact.value! + "T00:00:00Z");
      if (
        !Number.isFinite(date.getTime()) ||
        date.toISOString().slice(0, 10) !== fact.value
      ) fail();
    }
  }
  const hasFact = (id: string, kind?: string) =>
    result.facts.some((f) => f.id === id && (!kind || f.kind === kind));
  for (const action of result.actions) {
    if (!action.description_en.trim() || !action.description_zh.trim()) fail();
    if (action.requirement === "conditional") {
      if (
        !action.condition?.en.trim() || !action.condition?.zh.trim() ||
        !action.source_refs.length
      ) fail();
    } else if (action.condition !== null) fail();
    if (
      action.amount_fact_ids.some((id) => !hasFact(id, "amount")) ||
      action.appointment_fact_ids.some((id) => !hasFact(id, "appointment_date"))
    ) fail();
    if (
      action.deadline_fact_id !== null &&
      !hasFact(action.deadline_fact_id, "deadline")
    ) fail();
  }
  for (const summary of Object.values(result.summaries)) {
    if (
      ![summary.what_this_is, summary.what_to_do, summary.when].every((s) =>
        s.trim()
      )
    ) fail();
    if (
      summary.fact_ids.some((id) => !hasFact(id)) ||
      summary.action_ids.some((id) => !result.actions.some((a) => a.id === id))
    ) fail();
  }
  for (const key of ["fact_ids", "action_ids"] as const) {
    if (
      JSON.stringify([...new Set(result.summaries.en[key])].sort()) !==
        JSON.stringify([...new Set(result.summaries.zh[key])].sort())
    ) fail();
  }
  // An empty extraction cannot establish that the document requires nothing.
  // This is deterministic presentation copy, not a fabricated extracted fact.
  if (result.domain !== "unsupported" && result.actions.length === 0) {
    result.summaries.en.what_to_do =
      "No action steps were identified in the supplied pages; this does not establish that nothing needs to be done.";
    result.summaries.zh.what_to_do =
      "提供的页面中未识别到明确的办理步骤，不能据此认定无需处理。";
  }
  return result;
}
