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
  domain: "medical" | "insurance" | "unsupported";
  recipient: string | null;
  organization: string | null;
  category: typeof categories[number] | null;
  needs_review: boolean;
  facts: Fact[];
  actions: Action[];
  summaries: { en: Summary; zh: Summary };
}
export interface Verdict {
  verdict: "valid" | "retake" | "uncertain";
  reason: { en: string; zh: string };
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
export const verdictSchema = object({
  verdict: enumeration(["valid", "retake", "uncertain"]),
  reason: object({ en: str, zh: str }),
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
    domain: enumeration(["medical", "insurance", "unsupported"]),
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
      }),
    },
    summaries: object({ en: summary, zh: summary }),
  });
}
export const interpretationSchema = interpretationSchemaFor();
