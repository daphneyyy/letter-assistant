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
| Capture | UIImagePickerController native camera/retake confirmation |
| Local checks | Vision OCR and text-edge sharpness; no online photo validation in the current app |
| Spoken guidance | AVSpeechSynthesizer, English/Mandarin; no voice-question input |
| Interpretation | Deno local relay and operator-selected OpenAI-compatible Chat Completions vision model |
| Calendar | EventKit + EventKitUI creation editor; no broad calendar access |
| Persistence | In-memory photos/results only; content-free interrupted-editor flag in UserDefaults |

## Components

### Capture and Page Validation

`CaptureModel.swift` owns temporary ordered pages and result state. `CameraService.swift` uses Apple's camera. `PageQualityService.swift` prepares image data and checks local readability, preserving the accepted bytes for interpretation. Up to 10 pages, 10 MiB per image. Retaking replaces one page without disturbing others. Local uncertainty can be accepted explicitly; unreadable input cannot. No cropping/page-number checks. The app makes no validation-provider call before Finish capture.

### Letter Interpretation and Grounding

`LetterAPI.swift` sends ordered pages to the local relay. `supabase/functions/_shared/` currently contains reusable provider/schema/prompt/validation modules imported by the relay: the folder name does not indicate a Supabase deployment dependency. Keep these working modules; relocation is not necessary for this scope change.

The strict structured response contains bilingual summaries, contextual facts with original source references, and required/optional/conditional actions. Keep canonical values, uncertainty and date roles consistent. Four-section UI and generic medical/health-insurance interpretation remain as specified in PRD. No chat, conversation compression or database writes.

### Calendar Handoff and Reminder Suggestions

`CalendarProposal.swift` builds source-derived proposal roles and parses calendar dates strictly. `CalendarReviewView.swift` verifies user input and creates an EventKit event only for the system editor after confirmation. All-day date arithmetic uses calendar days across DST, with next-day exclusive end. Do not bind all-day events to a time zone; set `isAllDay` last because a non-nil time-zone assignment clears the flag. Timed appointments retain the selected zone.

The AI fact-kind enum now includes appointment_time (HH:mm) and appointment_timezone (IANA region identifier or UTC), alongside appointment_date (YYYY-MM-DD). The action’s appointment_fact_ids links these facts for the same appointment; prompts prohibit linking arrival times, office hours or another appointment’s time. Backend validation checks time/zone syntax and references; it does not establish extraction accuracy. `CalendarProposal.hasAppointmentTime` distinguishes an explicitly supplied time from a date-only placeholder. The no-AI appointment example constructs 10:00 AM with calendar arithmetic in the proposal time zone and marks the time as supplied; real AI proposals combine a single confirmed linked date/time using the stated zone, or the phone zone with a visible notice when no zone is stated. Multiple dates/times, uncertain zones, invalid clock values and repeated/nonexistent DST times cannot produce a prefilled appointment time. Evidence for all linked appointment facts is retained in source notes. Date-only responses remain readable but require manual time entry. All appointment paths still require explicit verification. Reminder dates are user-selected; automatic urgency/risk/preparation recommendations are outside this hackathon. Source cutoffs and conditions go into notes. Mark past dates and reconfirm after midnight. Saved/canceled/unknown results follow PRD. A content-free pending flag supports interrupted-editor recovery; store no event IDs and perform no calendar synchronization.

`CalendarAlertChoice` in `CalendarReviewView.swift` defines the preset choices listed in PRD. The review defaults to same-day 9 AM for all-day items and 15 minutes before for appointments. Its navigation-link picker also offers None and a custom date/time picker. Choice/date changes clear confirmation. Past alert times are warned about, not rejected.

`CalendarEditorRequest` carries the chosen alert and optional custom date. Presets are converted to fire dates using the review calendar/time zone, then attached with `EKAlarm(relativeOffset:)`. Minute/hour choices use elapsed offsets; day/week and morning choices use calendar arithmetic across DST. Custom alerts use `EKAlarm(absoluteDate:)` and remain fixed if the event date changes. None attaches no alarm. The system editor can still change the alert before saving. This adds no calendar reading, background notification service, or updates to previously saved events. Verify actual system-editor behavior and notification delivery on a phone separately from event-construction tests.

Debug builds expose no-AI fictional calendar examples under the expandable Demo tools section on the home screen. Titles are marked TEST. They use the real review/editor path, so saving creates a real calendar event. Release excludes this test entry.

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

Older-adult usability remains unverified. The current calendar form still exposes the complete preset list and detailed review fields; a concise action/date/notification summary and common-options-first design are proposed follow-ups, not existing components. The home-screen instruction to show all page edges is a known copy mismatch with the no-cropping requirement. Track it in the checklist. Test VoiceOver, contrast, long Chinese labels and the system-editor language transition on actual devices.

## Important Failure Modes

Local unreadability, camera denial, missing key/config, relay unreachable, provider quota/refusal/malformed output, lost network, source inconsistency, calendar unavailability/cancel/unknown results. Preserve captured pages through recoverable interpretation errors. Never label temporary results as saved. Finishing/restarting loses the temporary letter; system calendar events are independent.

## Verification and Build Sequence

Follow `checklist.md`: close capture/analysis acceptance, close calendar acceptance, then verify clone/setup and final demo. Maintain existing test evidence without treating older partial physical checks as complete. No account-isolation, email callback, cloud-save or two-phone acceptance work is required.

Before GitHub publication, select/add an open-source license, audit tracked content and history for secrets/private data, and try documented setup with operator-owned configuration. Do not publish as part of this scope edit. Preserve local credentials and signing while documenting how a new cloner selects their own team.

## Future Commercial Architecture

An in-app calendar synchronized with the phone calendar, login, chatbox, user-facing letter classification, expanded multilingual support and saved conversation-related records need a separate design. Save requirements are letter summaries, extracted information, summaries of user questions and added calendar items. Additional languages and their input/UI/output/speech coverage, authentication method, hosting, database, full transcript/photo retention, sync direction and conflict policy are not fixed by this hackathon spec. Previous Supabase/email choices are historical proposals, not current dependencies or permanent future commitments.
