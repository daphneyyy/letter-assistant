import {
  type Interpretation,
  interpretationSchemaFor,
  localizedInterpretationSchemaFor,
  legacyLocalizedInterpretationSchemaFor,
  type OutputLanguage,
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
  if (types.includes("integer")) return Number.isInteger(value) &&
    (schema.minimum === undefined || (value as number) >= schema.minimum) &&
    (schema.maximum === undefined || (value as number) <= schema.maximum);
  return typeof value === "boolean" && types.includes("boolean");
}
export function validateInterpretation(
  value: unknown,
  pageCount = 1,
): Interpretation {
  // Old interpretations lack these optional scheduling metadata fields.
  if (value && typeof value === "object" && Array.isArray((value as any).actions)) {
    value = structuredClone(value);
    for (const action of (value as any).actions) {
      if (action && typeof action === "object") for (const key of ["statement_balance_fact_id", "deadline_time", "deadline_timezone"]) {
        if (!Object.hasOwn(action, key)) action[key] = null;
      }
    }
  }
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
    if (fact.kind === "appointment_time" && fact.value !== null &&
        !/^([01]\d|2[0-3]):[0-5]\d$/.test(fact.value)) fail();
    if (fact.kind === "appointment_timezone" && fact.value !== null) {
      // Require a region identifier (or UTC), not ambiguous abbreviations.
      if (fact.value !== "UTC" && !fact.value.includes("/")) fail();
      try { new Intl.DateTimeFormat("en", { timeZone: fact.value }).format(); }
      catch { fail(); }
    }
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
    if (action.statement_balance_fact_id != null &&
        (result.domain !== "banking" || action.action_kind !== "payment" || !hasFact(action.statement_balance_fact_id, "amount"))) fail();
    if (action.deadline_time != null && (!action.deadline_fact_id || !/^([01]\d|2[0-3]):[0-5]\d$/.test(action.deadline_time))) fail();
    if (action.deadline_timezone != null) {
      if (!action.deadline_time || !action.deadline_timezone.includes("/")) fail();
      try { new Intl.DateTimeFormat("en", {timeZone:action.deadline_timezone}).format(); } catch { fail(); }
    }
    if (![action.calendar_title.en, action.calendar_title.zh].every((text) => text.trim() && text.length <= 100)) fail();
    if (![action.calendar_notes.en, action.calendar_notes.zh].every((text) => text.trim() && text.length <= 1500)) fail();
    if (!action.description_en.trim() || !action.description_zh.trim()) fail();
    if (action.suggested_duration_minutes !== null &&
        (action.deadline_fact_id !== null ||
         !action.appointment_fact_ids.some((id) =>
           result.facts.some((f) => f.id === id && ["appointment_date", "appointment_time"].includes(f.kind))))) fail();
    if (action.requirement === "conditional") {
      if (
        !action.condition?.en.trim() || !action.condition?.zh.trim() ||
        !action.source_refs.length
      ) fail();
    } else if (action.condition !== null) fail();
    if (
      action.amount_fact_ids.some((id) => !hasFact(id, "amount")) ||
      action.appointment_fact_ids.some((id) =>
        !result.facts.some((f) => f.id === id &&
          ["appointment_date", "appointment_time", "appointment_timezone"].includes(f.kind)))
    ) fail();
    if (
      action.deadline_fact_id !== null &&
      !hasFact(action.deadline_fact_id, "deadline")
    ) fail();
  }
  for (const summary of Object.values(result.summaries)) {
    if (
      ![summary.what_this_is, summary.what_to_note, summary.what_to_do, summary.when].every((s) =>
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
      "No action steps were identified in the supplied pages.";
    result.summaries.zh.what_to_do =
      "提供的页面中未识别到办理事项。";
  }
  return result;
}

export function validateLocalizedInterpretation(value: unknown, pageCount: number, language: OutputLanguage): Interpretation {
  if (value && typeof value === "object" && Object.hasOwn(value, "sources")) {
    return expandCompactInterpretation(value, pageCount, language);
  }
  // Accept earlier single-language responses without changing the app contract.
  if (value && typeof value === "object" && Array.isArray((value as any).actions)) {
    value = structuredClone(value);
    for (const action of (value as any).actions) if (action && typeof action === "object") {
      for (const key of ["statement_balance_fact_id", "deadline_time", "deadline_timezone"]) if (!Object.hasOwn(action, key)) action[key] = null;
    }
  }
  if (!matchesSchema(value, legacyLocalizedInterpretationSchemaFor(pageCount, language))) throw new SafeError("invalid_ai_output");
  const result: any = structuredClone(value);
  const text = (value: any) => ({en: value[language], zh: value[language]});
  for (const fact of result.facts) { fact.label = text(fact.label); fact.explanation = text(fact.explanation); }
  for (const action of result.actions) {
    const description = action[`description_${language}`];
    action.description_en = description; action.description_zh = description;
    if (action.condition !== null) action.condition = text(action.condition);
    action.calendar_notes = text(action.calendar_notes); action.calendar_title = text(action.calendar_title);
  }
  result.summaries = {en: result.summaries[language], zh: result.summaries[language]};
  return validateInterpretation(result, pageCount);
}

function expandCompactInterpretation(value: unknown, pageCount: number, language: OutputLanguage): Interpretation {
  if (!matchesSchema(value, localizedInterpretationSchemaFor(pageCount, language))) throw new SafeError("invalid_ai_output");
  const wire: any = structuredClone(value);
  const text = (value: string) => ({ en: value, zh: value });
  // Only exactly identical excerpts on the same page are deduplicated. No fuzzy merging.
  const sources = (ids: number[]) => {
    const seen = new Set<string>();
    return ids.map(id => {
      if (id >= wire.sources.length) throw new SafeError("invalid_ai_output");
      const source = wire.sources[id];
      if (!source.excerpt.trim()) throw new SafeError("invalid_ai_output");
      return source;
    }).filter(source => {
      const key = JSON.stringify([source.page, source.excerpt]);
      if (seen.has(key)) return false;
      seen.add(key); return true;
    });
  };
  const { sources: _sources, ...result } = wire;
  result.schema_version = 1;
  result.facts = wire.facts.map(({ source_ids, ...fact }: any) => ({
    ...fact, origin: "letter_fact", label: text(fact.label), explanation: text(fact.explanation), source_refs: sources(source_ids),
  }));
  result.actions = wire.actions.map(({ source_ids, description, ...action }: any) => ({
    ...action, description_en: description, description_zh: description,
    condition: action.condition === null ? null : text(action.condition),
    calendar_title: text(action.calendar_title), calendar_notes: text(action.calendar_notes), source_refs: sources(source_ids),
  }));
  result.summaries = { en: wire.summaries, zh: wire.summaries };
  return validateInterpretation(result, pageCount);
}
