export const categories = [
  "bills",
  "insurance_explanations",
  "appointments",
  "test_results",
  "medications",
] as const;
export type Status = "confirmed" | "not_specified" | "needs_verification";
export interface Bilingual {
  en: string;
  zh: string;
}
export interface Source {
  page: number;
  excerpt: string;
}
export interface Fact {
  id: string;
  kind:
    | "amount"
    | "document_date"
    | "deadline"
    | "appointment_date"
    | "appointment_time"
    | "appointment_timezone"
    | "effective_date"
    | "service_date"
    | "period"
    | "other";
  label: Bilingual;
  explanation: Bilingual;
  raw_text: string;
  value: string | null;
  currency: string | null;
  status: Status;
  origin: "letter_fact";
  source_refs: Source[];
}
export interface Action {
  id: string;
  description_en: string;
  description_zh: string;
  action_kind: string;
  requirement: "required" | "optional" | "conditional";
  condition: Bilingual | null;
  status: Status;
  source_refs: Source[];
  amount_fact_ids: string[];
  deadline_fact_id: string | null;
  appointment_fact_ids: string[];
  statement_balance_fact_id?: string | null;
  deadline_time?: string | null;
  deadline_timezone?: string | null;
  suggested_duration_minutes: number | null;
  calendar_notes: Bilingual;
  calendar_title: Bilingual;
}
export interface Summary {
  what_this_is: string;
  what_to_note: string;
  what_to_do: string;
  when: string;
  fact_ids: string[];
  action_ids: string[];
}
export interface Interpretation {
  schema_version: 1;
  domain: "medical" | "insurance" | "billing" | "banking" | "unsupported";
  recipient: string | null;
  organization: string | null;
  category: typeof categories[number] | null;
  needs_review: boolean;
  facts: Fact[];
  actions: Action[];
  summaries: { en: Summary; zh: Summary };
}
const str = { type: "string" };
const nullable = { type: ["string", "null"] };
const strings = { type: "array", items: str };
const enumeration = (values: string[]) => ({ type: "string", enum: values });
export const object = (properties: Record<string, unknown>) => ({
  type: "object",
  properties,
  required: Object.keys(properties),
  additionalProperties: false,
});
const bilingual = object({ en: str, zh: str });
const status = enumeration([
  "confirmed",
  "not_specified",
  "needs_verification",
]);
const summary = object({
  what_this_is: str,
  what_to_note: str,
  what_to_do: str,
  when: str,
  fact_ids: strings,
  action_ids: strings,
});
export function interpretationSchemaFor(pageCount = 1) {
  if (!Number.isInteger(pageCount) || pageCount < 1 || pageCount > 10) {
    throw new Error("Invalid page count");
  }
  const sources = {
    type: "array",
    items: object({
      page: {
        type: "integer",
        enum: Array.from({ length: pageCount }, (_, index) => index + 1),
      },
      excerpt: str,
    }),
  };
  return object({
    schema_version: { type: "integer", enum: [1] },
    domain: enumeration(["medical", "insurance", "billing", "banking", "unsupported"]),
    recipient: nullable,
    organization: nullable,
    category: { type: ["string", "null"], enum: [...categories, null] },
    needs_review: { type: "boolean" },
    facts: {
      type: "array",
      items: object({
        id: str,
        kind: enumeration([
          "amount",
          "document_date",
          "deadline",
          "appointment_date",
          "appointment_time",
          "appointment_timezone",
          "effective_date",
          "service_date",
          "period",
          "other",
        ]),
        raw_text: str,
        label: bilingual,
        explanation: bilingual,
        value: nullable,
        currency: nullable,
        status,
        origin: enumeration(["letter_fact"]),
        source_refs: sources,
      }),
    },
    actions: {
      type: "array",
      items: object({
        id: str,
        description_en: str,
        description_zh: str,
        action_kind: str,
        requirement: enumeration(["required", "optional", "conditional"]),
        condition: { ...bilingual, type: ["object", "null"] },
        status,
        source_refs: sources,
        amount_fact_ids: strings,
        deadline_fact_id: nullable,
        appointment_fact_ids: strings,
        calendar_notes: bilingual,
        calendar_title: bilingual,
        statement_balance_fact_id: nullable,
        deadline_time: nullable,
        deadline_timezone: nullable,
        suggested_duration_minutes: { type: ["integer", "null"], minimum: 1, maximum: 1440 },
      }),
    },
    summaries: object({ en: summary, zh: summary }),
  });
}
export const interpretationSchema = interpretationSchemaFor();

// Generate only the selected app language; the local adapter preserves legacy clients.
export type OutputLanguage = "en" | "zh";
export function localizedInterpretationSchemaFor(pageCount: number, language: OutputLanguage) {
  const schema: any = interpretationSchemaFor(pageCount);
  const text = object({ [language]: str });
  const fact = schema.properties.facts.items.properties;
  fact.label = text; fact.explanation = text;
  const action = schema.properties.actions.items;
  delete action.properties.description_en; delete action.properties.description_zh;
  action.properties[`description_${language}`] = str;
  action.properties.condition = { ...text, type: ["object", "null"] };
  action.properties.calendar_notes = text; action.properties.calendar_title = text;
  action.required = Object.keys(action.properties);
  schema.properties.summaries = object({ [language]: summary });
  return schema;
}
