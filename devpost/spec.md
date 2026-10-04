---
doc: spec
status: approved
---

# Letter Assistant — Hackathon Technical Specification

October 2, 2026: the learner removed email/accounts, archive and chat from hackathon delivery. This supersedes the prior Supabase/Resend/database blueprint. The existing local capture → analysis → calendar implementation is the delivery architecture.

## Where It Runs and How Someone Tries It

Clone the GitHub repository, configure an operator-owned compatible AI key/model in ignored `.env.local`, run the Deno relay on a Mac, configure the matching local relay URL/token in ignored `ios/Config/Debug.local.plist`, and install the Debug app through Xcode with the operator's own signing team. Phone and Mac use the same trusted local network. See README for exact instructions.

This is a source-built hackathon demo, not an App Store package or hosted service. Current Release builds intentionally exclude local relay configuration and cannot perform this local AI flow. No account, Supabase project, email service, domain or cloud deployment is needed.

## Stack

| Part | Implementation |
| --- | --- |
| iPhone | Swift/SwiftUI, iOS 17+; Xcode supporting the target device OS |
| Capture | UIImagePickerController camera; native file importer for PDF/photos; PhotosPicker for adding another photo |
| Local checks | Vision OCR and text-edge sharpness; no online photo validation in the current app |
| Spoken guidance | AVSpeechSynthesizer, English/Mandarin; no voice-question input |
| Interpretation | Deno local relay and operator-selected OpenAI-compatible Chat Completions vision model |
| Calendar | EventKit direct creation with write-only access; no existing-event reading |
| Persistence | In-memory photos/results only; content-free interrupted-save flag in UserDefaults |

## Components

### Capture and Page Validation

`CaptureModel.swift` owns temporary ordered pages and result state. The home file importer accepts PDF/image files up to 30 MB; LetterFileImport in PageQualityService.swift renders PDFs locally with PDFKit, bounded to the remaining 10-page capacity and 2,400 pixels on the longest edge. Prepare all images before appending any, inspect every imported page, and select the first failed page for review without discarding the others. No document content is sent to AI before Start analysis. `CameraService.swift` uses Apple's camera. `CaptureView.swift` uses PhotosPicker to load a selected image asynchronously and passes it to the same CaptureModel acceptance flow; selected-image access does not require full photo-library permission. Show loading/error states, preserve accepted pages on failure/cancel, and allow selecting additional pages within the existing limit. `PageQualityService.swift` prepares image data and checks local readability, preserving the accepted bytes for interpretation. Up to 10 pages, 10 MiB per image. Retaking replaces one page without disturbing others. Local uncertainty can be accepted explicitly; unreadable input cannot. No cropping/page-number checks. The app makes no validation-provider call before Finish capture.

### Letter Interpretation and Grounding

`LetterAPI.swift` sends ordered pages to the local relay. `supabase/functions/_shared/` currently contains reusable provider/schema/prompt/validation modules imported by the relay: the folder name does not indicate a Supabase deployment dependency. Keep these working modules; relocation is not necessary for this scope change.

The strict structured response contains bilingual summaries, contextual facts with original source references, and required/optional/conditional actions. Keep canonical values, uncertainty and date roles consistent. Four-section UI and generic medical/health-insurance interpretation remain as specified in PRD. No chat, conversation compression or database writes.

### Calendar Handoff and Reminder Suggestions

`CalendarProposal.swift` builds source-derived proposal roles and parses calendar dates strictly. `CalendarReviewView.swift` verifies user input and creates and directly saves an EventKit event when Add is tapped with valid fields. All-day date arithmetic uses calendar days across DST, with next-day exclusive end. Do not bind all-day events to a time zone; set `isAllDay` last because a non-nil time-zone assignment clears the flag. Timed appointments retain the selected zone.

The AI fact-kind enum now includes appointment_time (HH:mm) and appointment_timezone (IANA region identifier or UTC), alongside appointment_date (YYYY-MM-DD). The action’s appointment_fact_ids links these facts for the same appointment; prompts prohibit linking arrival times, office hours or another appointment’s time. Backend validation checks time/zone syntax and references; it does not establish extraction accuracy. `CalendarProposal.hasAppointmentTime` distinguishes an explicitly supplied time from a date-only placeholder. The no-AI appointment example constructs 10:00 AM with calendar arithmetic in the proposal time zone and marks the time as supplied; real AI proposals combine a single confirmed linked date/time using the stated zone, or the phone zone with a visible notice when no zone is stated. Multiple dates/times, uncertain zones, invalid clock values and repeated/nonexistent DST times cannot produce a prefilled appointment time. Evidence for linked appointment facts remains in the app source review; calendar notes use a separate event brief. Date-only responses remain readable but require manual time entry. There are no verification switches. A proposal with a date and explicit time is immediately eligible for handoff, subject to title/duration validity. Missing date/time values use the compact date/time control beside the row label on the review form; selecting a date/time updates it directly without a separate acknowledgment or date-entry sheet. Reminder dates are user-selected; automatic urgency/risk/preparation recommendations are outside this hackathon. Source cutoffs and conditions are preserved as concise calendar-note annotations. Mark past dates and reconfirm after midnight. Successful writes, denied permission, unavailable calendars and save errors follow PRD. A content-free pending flag supports interrupted-save recovery; store no event IDs and perform no calendar synchronization.

`CalendarAlertChoice` in `CalendarReviewView.swift` defines the preset choices listed in PRD. The review defaults to same-day 9 AM for all-day items and 15 minutes before for appointments. Its navigation-link picker also offers None and a custom date/time picker. Choice/date changes do not add a confirmation step. Past alert times are warned about, not rejected.

`CalendarEventRequest` carries the chosen alert and optional custom date. Presets are converted to fire dates using the review calendar/time zone, then attached with `EKAlarm(relativeOffset:)`. Minute/hour choices use elapsed offsets; day/week and morning choices use calendar arithmetic across DST. Custom alerts use `EKAlarm(absoluteDate:)` and remain fixed if the event date changes. None attaches no alarm. The app form allows alert changes before adding. This adds no calendar reading, background notification service, or updates to previously saved events. Verify actual direct-save behavior and notification delivery on a phone separately from event-construction tests.

Debug builds expose no-AI fictional calendar examples under the expandable Demo tools section on the home screen. Titles are marked TEST. They use the real review/direct-save path, so saving creates a real calendar event. Release excludes this test entry.

`CalendarSaveModel` serializes the add operation, rejects repeated/concurrent saves, and exposes in-flight/error/success state. `SystemCalendarWriter` requests `requestWriteOnlyAccessToEvents()` only if needed; `NSCalendarsWriteOnlyAccessUsageDescription` explains the permission. It assigns `defaultCalendarForNewEvents`, checks writability and calls `save(_:span:commit:)`. No EventKitUI editor is presented. Permission rejection offers Settings; unavailable calendar/save error leaves the review intact. A content-free `calendarSavePending` flag surrounds the write, with legacy interrupted-editor flag recovery retained. No automatic retries or calendar queries are used. Test harnesses inject writers and never create real events; physical permission/write/notification validation remains open.

### Timed-Event Duration

Each AI action includes nullable `suggested_duration_minutes`. The schema and backend enforce an integer from 1 to 1,440, allowed only for an action linked to an appointment date/time without a deadline. The prompt distinguishes this scheduling estimate from source facts, preferring stated durations/intervals and otherwise estimating from event type with 30 minutes as the generic fallback. All-day actions use null; estimates must not be inserted into grounded facts or quoted source text.

Swift decodes the new field optionally for older responses. `CalendarProposal` passes a bounded estimate only to timed appointments; `CalendarDurationPolicy` validates estimates and custom input and supplies preset values. The review uses the estimate or 30-minute fallback, replacing the stepper with a navigation picker and optional numeric custom entry. The end preview uses the selected time zone. Invalid custom input blocks handoff; valid changes need no additional acknowledgment. EventKit end is start plus the selected number of elapsed minutes; all-day end-date arithmetic is unchanged. AI estimation quality and physical-device acceptance remain separate from deterministic contract/UI tests.

### Calendar Note Content

The action schema includes required bilingual `calendar_title` (nonempty, at most 100 characters per language) for concise event headings. Swift reads it optionally for older results; payment proposals additionally carry classified bill type, billing organization and confirmed linked payment amounts from interpretation context, preventing generic AI titles/notes from dropping those details. Source refs are deduplicated by page and whitespace-normalized excerpt, preserving order and distinct pages. Raw deadline text no longer appears as a duplicated Letter date field.

The action schema adds required bilingual `calendar_notes`, validated as nonempty and at most 1,500 characters per language. The prompt requests source-grounded event briefs, excluding UI instructions, assistant conversation, duplicated event fields and estimated-duration disclaimers. Swift decodes this field optionally for older responses. `CalendarNoteBuilder` uses the selected-language note (or legacy action description) and preserves conditions, optionality, explicit deadline clock/qualifier text and uncertainty, without duplicating an already represented confirmed date-only deadline. `CalendarProposal.eventNotes` stays separate from review source excerpts. `CalendarReviewView` previews and saves the contextual note, adding the original source deadline when the user schedules a different calendar day; source/review text is no longer concatenated into notes. Deterministic validation does not prove live model grounding or writing quality.

### App Shell and Language

`CaptureView.swift` provides capture, interpretation, source details, language selection and calendar entry points. No authentication state, tabs, archive, chatbox, user profile, account cache or login gate.

## Data Model and Contracts

The current Swift models in `Models/Letter.swift` and validated schema in `_shared/contracts.ts` are authoritative for wire fields. Facts distinguish amount/document date/deadline/appointment date/time/time zone/effective/service date/period/other. Only linked deadline facts populate deadline proposals. Existing classification metadata remains an analysis detail, not a saved filing system.

`POST /interpret` uses a local bearer token and `{capture_id, pages:[{page_id, image_base64, local_readability:true}]}`. This flag describes a client-side check, not server attestation. The relay retains authentication, image/page/body limits and result validation. Its legacy `/validate-page` path may remain for old clients/tests; the current iPhone does not call it. No user access token or email verification is involved.

## External Services and Dependencies

`AI_BASE_URL`, `AI_MODEL`, `AI_API_KEY`, `AI_FREE_ONLY` select the operator's provider. The provider must accept images and the structured JSON-schema contract. Endpoint uses HTTPS and disables redirects; credentials remain on the Mac. When enabled, free-only mode is restricted to OpenRouter free models. No paid fallback is automatic. Model availability, quota and pricing belong to the operator's provider; a checked-in model example is not an availability guarantee.

`DEV_ACCESS_TOKEN` is a random shared local relay token of at least 32 characters, not an account login. Relay binds loopback or an explicit private IPv4 address; phone builds use the Mac's private address. Current phone↔Mac HTTP is a trusted-LAN fictional-data demo transport, not public hosting. Provider traffic uses HTTPS. No Supabase, SMTP, Resend, cloud storage or calendar OAuth setup.

## File Structure

- `ios/LetterAssistant/`: app, capture/analysis UI, camera/readability/relay services, calendar review and models.
- `ios/LetterAssistantTests/`, `ios/LetterAssistantUITests/`: focused behavior tests.
- `dev-tools/`: local relay and its provider/contract/multi-page tests.
- `supabase/functions/_shared/`: shared AI implementation; no running Supabase service.
- `fixtures/`: fictional letters and expected facts.
- `.env.example`, `ios/Config/Debug.example.plist`: secret-free setup examples.
- `devpost/`: approved scope/PRD/spec/checklist and historical build evidence.

## Look and Feel

Retain accepted four-section explanations, concise contextual wording, expanded source detail on demand, large Dynamic Type, Chinese wrapping, 44-point controls, basic VoiceOver and quiet successful photo checks. The subsequent user-requested UI pass adds adaptive grouped backgrounds with teal accents, a prominent capture action, a three-step introduction, selected-page styling and expandable original photos. The decorative envelope logo has been removed. This supersedes the earlier statement that the scope revision itself included no redesign.

Older-adult usability remains unverified. The current calendar form still exposes the complete preset list and detailed review fields; a concise action/date/notification summary and common-options-first design are proposed follow-ups, not existing components. The home-screen instruction to show all page edges is a known copy mismatch with the no-cropping requirement. Track it in the checklist. Test VoiceOver, contrast, long Chinese labels and the system-permission language transition on actual devices.

## Important Failure Modes

Local unreadability, camera denial, missing key/config, relay unreachable, provider quota/refusal/malformed output, lost network, source inconsistency, calendar unavailability/cancel/unknown results. Preserve captured pages through recoverable interpretation errors. Never label temporary results as saved. Finishing/restarting loses the temporary letter; system calendar events are independent.

## Verification and Build Sequence

Follow `checklist.md`: close capture/analysis acceptance, close calendar acceptance, then verify clone/setup and final demo. Maintain existing test evidence without treating older partial physical checks as complete. No account-isolation, email callback, cloud-save or two-phone acceptance work is required.

Before GitHub publication, select/add an open-source license, audit tracked content and history for secrets/private data, and try documented setup with operator-owned configuration. Do not publish as part of this scope edit. Preserve local credentials and signing while documenting how a new cloner selects their own team.

## Future Commercial Architecture

An in-app calendar synchronized with the phone calendar, login, chatbox, user-facing letter classification, expanded multilingual support and saved conversation-related records need a separate design. Save requirements are letter summaries, extracted information, summaries of user questions and added calendar items. Additional languages and their input/UI/output/speech coverage, authentication method, hosting, database, full transcript/photo retention, sync direction and conflict policy are not fixed by this hackathon spec. Previous Supabase/email choices are historical proposals, not current dependencies or permanent future commitments.


Calendar review defaults to `TimeZone.current` for all proposal kinds. All-day source dates preserve their calendar day in that initial zone; explicitly zoned appointments preserve their absolute instant. Every proposal exposes the in-page zone menu and a compact date control beside its label. Changing zone reinterprets the displayed wall date/time in the chosen zone; alerts and end dates use that zone. Original confirmed deadlines remain immutable source facts and are appended to preview/saved notes only when scheduling on another day. `CaptureView` passes the interpretation's classified document context to proposal construction so payment headings and notes retain bill type, organization and linked amounts independently of generic AI wording. Summary and calendar prompts explicitly request those identifying details.


Build environments: shared `LetterAssistant-Test` and `LetterAssistant-Prod` schemes select Debug and Release respectively. Debug defines `TEST_BUILD`; fictional photo buttons, demo labels/calendar tools and simulator harnesses are compiled only there. Fixtures are copied by the environment build phase only for Debug and removed for Release; the app's unconditional Resources phase no longer bundles them. Debug loads only `Debug.local.plist`, Release only `Prod.local.plist`; both files are ignored and only the selected configuration is packaged. Test requires the existing local HTTP relay, while Prod accepts HTTPS or trusted local HTTP. No backend deployment is implied. Both builds currently share the application bundle ID.
