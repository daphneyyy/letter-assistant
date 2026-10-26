---
doc: spec
status: approved
---

# Letter Assistant — Hackathon Technical Specification

The delivery architecture is a native iPhone capture → local readability checks → analysis → calendar flow with a Mac-hosted relay. Accounts, cloud archives and chat are outside this hackathon.

## Product Audience and Language Boundary

The capture → explanation → reviewed calendar flow serves anyone who needs clearer understanding of supported letters and their next steps. It is not limited to people with low English proficiency, older adults or immigrants.

The current implementation accepts English source documents and generates explanations, actions and calendar text in the selected English or Simplified Chinese app language. It does not generate both languages for each request. Additional languages are a future expansion: input recognition, provider output contracts, localization, speech and acceptance checks need their own implementation and verification. This documentation update does not add language support to the code.

## Where It Runs and How Someone Tries It

Clone [https://github.com/daphneyyy/letter-assistant](https://github.com/daphneyyy/letter-assistant), configure an operator-owned compatible AI key/model in ignored `.env.local`, run the Deno relay on a Mac, configure the matching local relay URL/token in ignored `ios/Config/Debug.local.plist`, and install the Debug app through Xcode with the operator's own signing team. Phone and Mac use the same trusted local network. See README for exact instructions. Current repository/video links, publication checks and Devpost status are recorded in [shipping.md](shipping.md); the source walkthrough is [app-map.html](app-map.html).

This is a source-built hackathon demo, not an App Store package or hosted service. The Prod/Release build packages only the ignored Prod.local.plist and accepts HTTPS or trusted local HTTP relay settings. It excludes fictional fixtures and demo tools; compilation alone does not establish a working AI connection. No account, Supabase project, email service, domain or cloud deployment is needed.

### Build Environments

Shared `LetterAssistant-Test` and `LetterAssistant-Prod` schemes select Debug and Release respectively. Debug defines `TEST_BUILD`; fictional photo buttons, demo labels/calendar tools and simulator harnesses are compiled only there. Fixtures are copied by the environment build phase only for Debug and removed for Release; the app's unconditional Resources phase no longer bundles them. Debug loads only `Debug.local.plist`, Release only `Prod.local.plist`; both files are ignored and only the selected configuration is packaged. Test requires the existing local HTTP relay, while Prod accepts HTTPS or trusted local HTTP. No backend deployment is implied. Both builds currently share the application bundle ID.

## Stack

| Part | Implementation |
| --- | --- |
| iPhone | Swift/SwiftUI, iOS 17+; Xcode supporting the target device OS |
| Capture | UIImagePickerController camera; native PDF file importer; PhotosPicker for initial and additional photos |
| Local checks | Vision OCR and text-edge sharpness; no online photo validation in the current app |
| Spoken guidance | AVSpeechSynthesizer, English/Mandarin; no voice-question input |
| Interpretation | Deno local relay and operator-selected OpenAI-compatible Chat Completions vision model |
| Calendar | EventKit direct creation with write-only access; no existing-event reading |
| Persistence | In-memory photos/results only; content-free interrupted-save flag in UserDefaults |

## Components

### Capture and Page Validation

`CaptureModel.swift` owns temporary ordered pages and result state. The home file importer accepts PDFs only, up to 30 MiB (shown as 30 MB in the interface); LetterFileImport in PageQualityService.swift renders PDFs locally with PDFKit, bounded to the remaining 10-page capacity and 2,400 pixels on the longest edge. Prepare all images before appending any, inspect every imported page, and select the first failed page for review without discarding the others. No document content is sent to AI before Analyze document / 分析文档. `CameraService.swift` uses Apple's camera. `CaptureView.swift` uses PhotosPicker to load a selected image asynchronously and passes it to the same CaptureModel acceptance flow; selected-image access does not require full photo-library permission. Show loading/error states, preserve accepted pages on failure/cancel, and allow selecting additional pages within the existing limit. `PageQualityService.swift` prepares image data and checks local readability, rerendering full-size oriented pixels as JPEG at quality 0.95 to strip metadata and preserving the accepted bytes for interpretation. The shortest edge must be at least 800 pixels; photo preparation does not downsample the submitted image. Up to 10 pages, 10 MiB per image. Retaking replaces one page without disturbing others. Local uncertainty can be accepted explicitly; unreadable input cannot. No cropping/page-number checks or validation-provider calls.

### Letter Interpretation and Grounding

Unified `AI_*` configuration uses the compatible `/chat/completions` transport. Without unified settings, the legacy `OPENROUTER_*` path uses Chat Completions; otherwise the legacy `OPENAI_*` path uses OpenAI `/v1/responses`. These are configuration-selected paths, not automatic provider failover. For the OpenAI Chat Completions endpoint, send the JSON schema only in strict `response_format`, rather than duplicating it in the system prompt. Other compatible providers retain their existing prompt copy. Keep output validation, full ordered images and the configured model unchanged. `InterpretationProgressView` uses `TimelineView` to display elapsed seconds from presentation, with explanatory copy after 20 seconds. This is waiting feedback, not measured stage progress or a latency guarantee.

`LetterAPI.swift` sends ordered pages to the local relay. `supabase/functions/_shared/` currently contains reusable provider/schema/prompt/validation modules imported by the relay: the folder name does not indicate a Supabase deployment dependency.

The provider generates only the selected app language in its strict structured response, with contextual facts, original source references and required/optional/conditional actions. The local compatibility adapter fills legacy language fields without generating another translation. Keep canonical values, uncertainty and date roles consistent. Four-section UI and medical/health-insurance and everyday-billing interpretation remain as specified in PRD. No chat, conversation compression or database writes.

### Calendar Handoff and Reminder Suggestions

`CalendarProposal.swift` builds source-derived proposal roles and parses calendar dates strictly. `CalendarReviewView.swift` verifies user input and creates and directly saves an EventKit event when Add is tapped with valid fields. All-day date arithmetic uses calendar days across DST, with next-day exclusive end. Do not bind all-day events to a time zone; set `isAllDay` last because a non-nil time-zone assignment clears the flag. Timed appointments retain the selected zone. Review defaults to the phone zone for date-only items and appointments, while explicit timed cutoffs retain their source zone. All-day dates preserve the source calendar day; explicitly zoned appointments preserve their absolute instant when initially displayed in the phone zone. Changing the review zone reinterprets the displayed wall date/time in the chosen zone, which also controls alerts and end dates.

The AI fact-kind enum includes appointment_time (HH:mm) and appointment_timezone (IANA region identifier or UTC), alongside appointment_date (YYYY-MM-DD). The action’s appointment_fact_ids links these facts for the same appointment; prompts prohibit linking arrival times, office hours or another appointment’s time. Backend validation checks time/zone syntax and references; it does not establish extraction accuracy. `CalendarProposal.hasAppointmentTime` distinguishes an explicitly supplied time from a date-only placeholder. The no-AI appointment example constructs 10:00 AM with calendar arithmetic in the proposal time zone and marks the time as supplied; real AI proposals combine a single confirmed linked date/time using the stated zone, or the phone zone with a visible notice when no zone is stated. Multiple dates/times, uncertain zones, invalid clock values and repeated/nonexistent DST times cannot produce a prefilled appointment time. Evidence for linked appointment facts remains in the app source review; calendar notes use a separate event brief. Date-only responses remain readable but require manual time entry. There are no verification switches. A proposal with a date and explicit time is immediately eligible for handoff, subject to title/duration validity. Missing date/time values use compact controls on separate labeled rows of the review form; selecting a date/time updates it directly without a separate acknowledgment or date-entry sheet. Undated personal reminders prefill tomorrow and permit saving that date immediately or changing it with shortcuts/the date picker; automatic urgency/risk/preparation recommendations are outside this hackathon. Source cutoffs and conditions are preserved as concise calendar-note annotations. Mark past dates and reconfirm after midnight. Successful writes, denied permission, unavailable calendars and save errors follow PRD. A content-free pending flag supports interrupted-save recovery; store no event IDs and perform no calendar synchronization.

`CalendarAlertChoice` in `CalendarReviewView.swift` defines the preset choices listed in PRD. The review defaults to previous-day 9 AM for deadlines, same-day 9 AM for undated personal reminders, and 1 day before for appointments. Its in-page alert menu also offers None and a custom date/time picker. Choice/date changes do not add a confirmation step. Past alert times are warned about, not rejected.

`CalendarEventRequest` carries the chosen alert and optional custom date. Presets are converted to fire dates using the review calendar/time zone, then attached with `EKAlarm(relativeOffset:)`. Minute/hour choices use elapsed offsets; day/week and morning choices use calendar arithmetic across DST. Custom alerts use `EKAlarm(absoluteDate:)` and remain fixed if the event date changes. None attaches no alarm. The app form allows alert changes before adding. This adds no calendar reading, background notification service, or updates to previously saved events. Verify actual direct-save behavior and notification delivery on a phone separately from event-construction tests.

Debug builds expose no-AI fictional calendar examples under the expandable Demo tools section on the home screen. Titles are marked TEST. They use the real review/direct-save path, so saving creates a real calendar event. Release excludes this test entry.

`CalendarSaveModel` serializes the add operation, rejects repeated/concurrent saves, and exposes in-flight/error/success state. `SystemCalendarWriter` requests `requestWriteOnlyAccessToEvents()` only if needed; `NSCalendarsWriteOnlyAccessUsageDescription` explains the permission. It assigns `defaultCalendarForNewEvents`, checks writability and calls `save(_:span:commit:)`. No EventKitUI editor is presented. Permission rejection offers Settings; unavailable calendar/save error leaves the review intact. A content-free `calendarSavePending` flag surrounds the write, with legacy interrupted-editor flag recovery retained. No automatic retries or calendar queries are used. Test harnesses inject writers and never create real events; the learner confirmed the core flow saved an event on an iPhone. Detailed permission-denial/recovery, event-field/alert and notification-delivery checks remain open.

The calendar-save confirmation button reads Back to result / 返回解读结果.

### Timed-Event Duration

Each AI action includes nullable `suggested_duration_minutes`. The schema and backend enforce an integer from 1 to 1,440, allowed only for an action linked to an appointment date/time without a deadline. The prompt distinguishes this scheduling estimate from source facts, preferring stated durations/intervals and otherwise estimating from event type with 30 minutes as the generic fallback. All-day actions use null; estimates must not be inserted into grounded facts or quoted source text.

Swift decodes the new field optionally for older responses. `CalendarProposal` passes a bounded estimate only to timed appointments; `CalendarDurationPolicy` validates estimates and selected whole-minute durations. The review uses the estimate or 30-minute fallback. A compact duration capsule opens a SwiftUI popover with hour/minute wheels only when tapped, using popover adaptation on iPhone. Selection updates immediately and persists on dismissal; 24 hours restricts the minute wheel to zero. The end preview uses the selected time zone. A zero-minute or otherwise invalid duration blocks handoff; valid changes need no additional acknowledgment. EventKit end is start plus the selected number of elapsed minutes; all-day end-date arithmetic is unchanged. AI estimation quality and physical-device acceptance remain separate from deterministic contract/UI tests.

### Calendar Note Content

The action schema includes required selected-language `calendar_title` (nonempty, at most 100 characters per language) for concise event headings. Swift reads it optionally for older results; payment proposals additionally carry classified bill type, billing organization and confirmed linked payment amounts from interpretation context, preventing generic AI titles/notes from dropping those details. Source refs are deduplicated by page and whitespace-normalized excerpt, preserving order and distinct pages. Raw deadline text no longer appears as a duplicated Letter date field.

The action schema includes required selected-language `calendar_notes`, validated as nonempty and at most 1,500 characters per language. The prompt requests source-grounded event briefs, excluding UI instructions, assistant conversation, duplicated event fields and estimated-duration disclaimers. Swift decodes this field optionally for older responses. `CalendarNoteBuilder` uses the selected-language note (or legacy action description) and preserves conditions, optionality, explicit deadline clock/qualifier text and uncertainty, without duplicating an already represented confirmed date-only deadline. `CalendarProposal.eventNotes` stays separate from review source excerpts. `CalendarReviewView` previews and saves the contextual note, adding the original source deadline when the user schedules a different calendar day; source/review text is no longer concatenated into notes. Deterministic validation does not prove live model grounding or writing quality.

### App Shell and Language

The app-specific iPhone language preference selects English or Simplified Chinese and may override the phone language. New analysis generates only the selected language, including explanations, action descriptions, conditions and calendar titles/notes. Source quotations retain their original language; the compatibility adapter fills legacy language fields with identical selected text without generating a translation. Changing the language restarts the app and clears the unsaved letter.

`CaptureView.swift` provides capture, interpretation, source details, language selection and calendar entry points. No authentication state, tabs, archive, chatbox, user profile, account cache or login gate.

## Data Model and Contracts

The domain enum includes `medical`, `insurance`, `billing`, `banking` and `unsupported`. Informational deposit/checking/savings statements may use category null/needs_review true while remaining supported; payment-oriented bank/credit-card statements use `bills`. The UI heading handles banking independently of category, so an informational statement is not mislabeled as insurance. Banking payment calendar context retains the source-specific heading/minimum-payment wording and only confirmed linked amounts. Existing contract/date-role validation remains.

Everyday billing uses existing `bills` classification metadata and existing amount/date/action/source-reference contracts; no new persistence or service is added. Prompts distinguish outstanding balances, received payments, scheduled autopay, renewal dates and explicit cancellation/payment cutoffs. Swift bill headings and calendar fallback context handle the new domain without labeling everyday bills as medical or insurance. For billing payment actions, retain the provider's source-specific calendar title and supplement missing organization/confirmed linked amount. Historical responses remain readable.

The current Swift models in `Models/Letter.swift` and validated schema in `_shared/contracts.ts` are authoritative for wire fields. Facts distinguish amount/document date/deadline/appointment date/time/time zone/effective/service date/period/other. Only linked deadline facts populate deadline proposals. Existing classification metadata remains an analysis detail, not a saved filing system.

`POST /interpret` uses a local bearer token and `{capture_id, language, pages:[{page_id, image_base64, local_readability:true}]}`. This flag describes a client-side check, not server attestation. The relay retains authentication, image/page/body limits and result validation. The legacy AI `/validate-page` endpoint and provider quality-check prompts/methods have been removed; only `/interpret` can invoke AI. Each submitted page must carry the local readability decision; no server validation token is required. No user access token or email verification is involved.

### Action Balance and Cutoff Fields

Action metadata includes nullable statement_balance_fact_id, deadline_time (HH:mm) and deadline_timezone (IANA). Legacy responses default these to null. Payment amount_fact_ids retain the source-required minimum; the separate confirmed statement balance supplies the user-requested calendar title/notes. Older credit-card interpretations use uniquely identifiable balance fact labels/quotes as fallback, never account funds. CalendarProposal uses deadline kind with hasDeadlineTime/isTimedEvent; explicit cutoffs preserve the source instant/zone, and CalendarReviewView saves a one-minute deadline marker instead of an all-day event. The cutoff is not a recommended task start. Date-only deadlines retain existing all-day behavior. Older explicit Eastern clock text can be read from that deadline fact’s evidence, without guessing missing times/zones.

### Compact Provider Output

The selected-language provider response uses plain text fields, one summaries object and a shared sources array of {page, excerpt}. Fact/action source_ids reference zero-based array indices; source page numbers remain one-based. The adapter supplies schema_version=1 and fact origin=letter_fact, restores the existing bilingual-shaped client fields using identical selected-language text, expands source_refs and runs the unchanged app semantic validation. Only exactly identical same-page quotes are deduplicated; different pages or excerpts remain distinct. Out-of-range, negative and fractional indices fail safely. Fact values/status, labels/explanations/raw_text, summary references, action conditions, payment/balance links, time zones, deadline clocks, duration estimates and calendar titles/notes remain available. Legacy single-language and bilingual provider formats remain accepted on their existing paths.

## External Services and Dependencies

`AI_BASE_URL`, `AI_MODEL`, `AI_API_KEY`, `AI_FREE_ONLY` select the operator's provider. The provider must accept images and the structured JSON-schema contract. Endpoint uses HTTPS and disables redirects; credentials remain on the Mac. When enabled, free-only mode is restricted to OpenRouter free models. No paid fallback is automatic. Model availability, quota and pricing belong to the operator's provider; a checked-in model example is not an availability guarantee.

`DEV_ACCESS_TOKEN` is a random shared local relay token of at least 32 characters, not an account login. Relay binds loopback or an explicit private IPv4 address; phone builds use the Mac's private address. Current phone↔Mac HTTP is a trusted-LAN fictional-data demo transport, not public hosting. Provider traffic uses HTTPS. No Supabase, SMTP, Resend, cloud storage or calendar OAuth setup.

## File Structure

- `ios/LetterAssistant/`: app, capture/analysis UI, camera/readability/relay services, calendar review and models.
- `ios/LetterAssistantTests/`, `ios/LetterAssistantUITests/`: focused behavior tests.
- `dev-tools/`: local relay and its provider/contract/multi-page tests.
- `supabase/functions/_shared/`: shared AI implementation; no running Supabase service.
- `fixtures/`: fictional letters and expected facts.
- `.env.example`, `ios/Config/Debug.example.plist`, `ios/Config/Prod.example.plist`: secret-free setup examples.
- `devpost/`: approved scope/PRD/spec/checklist and current verification evidence.

## Look and Feel

Retain accepted four-section explanations, concise contextual wording, expanded source detail on demand, large Dynamic Type, Chinese wrapping, 44-point controls, basic VoiceOver and quiet successful photo checks. The interface uses a warm off-white light background and adaptive dark styling with teal/mint accents. Home has separate camera, photo-library and PDF actions and a collapsed three-step introduction. Captured pages use horizontal swiping, a page-count jump menu and a full-screen zoom viewer; original photos on results are expandable. The decorative envelope logo has been removed.

Independent-use usability across representative users remains unverified; review should cover different document familiarity, language preferences, ages and accessibility needs. The current calendar form still exposes the complete preset list and detailed review fields; a concise action/date/notification summary and common-options-first design are proposed follow-ups, not existing components. Home-screen capture guidance asks for clear, readable text one page at a time, consistent with the no-cropping requirement. Test VoiceOver, contrast, long Chinese labels and the system-permission language transition on actual devices.

## Important Failure Modes

Local unreadability, camera denial, missing key/config, relay unreachable, provider quota/refusal/malformed output, lost network, source inconsistency, calendar unavailability/cancel/unknown results. Preserve captured pages through recoverable interpretation errors. Never label temporary results as saved. Finishing/restarting loses the temporary letter; system calendar events are independent.

## Verification and Build Sequence

Follow `checklist.md`: close capture/analysis acceptance, close calendar acceptance, then verify clone/setup and final demo. Retain the confirmed core iPhone hands-on pass and existing automated/setup evidence; keep detailed physical edge cases and final readiness separate. No account-isolation, email callback, cloud-save or two-phone acceptance work is required.

The project uses MIT; the root LICENSE contains the license text. Before GitHub publication, audit tracked content and history for secrets/private data, and try documented setup with operator-owned configuration. The repository is currently private and will be made public for submission. Preserve local credentials and signing while documenting how a new cloner selects their own team.

## Future Commercial Architecture

An in-app calendar synchronized with the phone calendar, login, chatbox, user-facing letter classification, expanded multilingual support and saved conversation-related records need a separate design. Save requirements are letter summaries, extracted information, summaries of user questions and added calendar items. Additional languages and their input/UI/output/speech coverage, authentication method, hosting, database, full transcript/photo retention, sync direction and conflict policy are not fixed by this hackathon spec. Future service choices require separate planning.
