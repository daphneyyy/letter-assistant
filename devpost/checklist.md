---
doc: checklist
status: approved
---

# Letter Assistant — Hackathon Build Checklist

Build mode: Fast. The approved scope is capture → local photo checks → analysis → creation in the iPhone calendar. No account, email, archive, chatbox or synchronization is required. Operators supply their own API key.

## Audience and Language Boundary

The product helps anyone who wants to understand supported letters and identify actions and dates; the audience is not limited by English proficiency, age or immigration status. Current source documents are English, with explanations and calendar text generated in the selected English or Simplified Chinese app language. Additional languages are planned for future versions and require separate implementation and acceptance checks; this positioning update does not mark them as completed.

## Current State

- Capture, analysis and calendar creation are implemented. The learner confirmed the iPhone capture/retake → explanation → saved Calendar event hands-on check passed. Detailed edge-case and target-user checks below remain open.
- Backend type checking and 37 tests passed. The latest iPhone simulator unit suite reported 47 passing tests with zero failures, but Xcode stalled during cleanup and the runner was stopped; no final TEST SUCCEEDED result is claimed for that run. Focused UI tests have separate passing evidence, not a complete latest combined run.
- An isolated source snapshot passed type checking, an unsigned Test simulator build, selected-config/fixture packaging, loopback relay startup, token authentication and the missing-provider response. It used fresh placeholder configuration, not existing credentials; it does not establish a new operator's phone signing or live AI setup.
- Individual live fictional-letter cases cover billing, banking, conditional actions, EOB, no-action/no-deadline cases and selected-language output. These samples do not establish universal accuracy; conditional enrollment extraction remains a reliability concern.
- A scan of 441 reachable historical blobs found no current local credential matches or common credential/private-key patterns. Private configuration, captures and learner-profile paths were absent from reachable history. This scoped scan does not prove absence of every possible sensitive item; review intended additions before publication.
- MIT is selected and tracked. The author confirmed no code or materials were copied or adapted from prior projects, tutorials, templates or other repositories, apart from the separately documented standard tools/frameworks and Skill Pack.
- Repository: [letter-assistant](https://github.com/daphneyyy/letter-assistant). It is currently private; the learner plans to make it public for submission. Public access and GitHub license detection will be checked then.
- Final readiness, remaining acceptance and the learning wrap-up/app map are unfinished. Existing checkbox states are preserved.

## Slices

- [ ] **1. Close capture, local photo checks and real analysis acceptance**
  Becomes usable: Photograph or import one or multiple pages, handle readability/retakes and read a grounded interpretation in the selected English or Chinese app language without logging in.
  Why now: Core implementation exists; complete the remaining real-use evidence before declaring the demo ready.
  PRD ref: `prd.md > Page Capture and Validation`; `prd.md > Actionable Explanation`; `prd.md > Recovery Behavior`.
  Spec ref: `spec.md > Capture and Page Validation`; `spec.md > Letter Interpretation and Grounding`; `spec.md > Look and Feel`.
  Build: Preserve the native camera, local-only check, Use anyway for uncertain quality, page order, four-section explanation and retries. Fix only relevant acceptance failures; no account/archive work.
  Verify (mechanical): Run checks appropriate to actual fixes. Compare real fictional provider output against expected source facts, including conditional actions, EOB/no-action/no-deadline cases and both languages. Record any provider quota blocker honestly. Verify physical capture/retake and basic accessibility without inferring coverage from a general approval.
  Learner check: Capture a fictional letter, retake an unreadable page, try an uncertain image and inspect the explanation/source details. Confirm English/Chinese readability and guidance.
  Commit: `Complete hackathon capture and analysis acceptance`

- [ ] **2. Close creation-only phone calendar acceptance**
  Becomes usable: Review an action and save a correct date-only all-day deadline/reminder, timed cutoff marker or timed appointment in the phone calendar.
  Why now: Handoff and the all-day fix exist; verify the actual saved event and recovery outcomes.
  PRD ref: `prd.md > External Calendar Handoff`.
  Spec ref: `spec.md > Calendar Handoff and Reminder Suggestions`.
  Build: Preserve the requested alert presets, None and custom date/time, alongside manual reminder-date selection, verified appointment time/zone, conditions, source notes, direct EventKit saving with write-only permission, explicit success/error state and interrupted-result handling. Automatic urgency-based recommendations are not required. No calendar-reading, in-app calendar or sync work.
  Verify (mechanical): Use existing date-policy/EventKit tests and UI evidence; run targeted tests for subsequent fixes. On the iPhone check newly saved all-day events, appointment date/time/duration/zone, notes, preset/custom/None alerts and notification delivery, permission denial/Not now, unavailable calendar and interrupted result. Do not silently alter previously saved events.
  Learner check: Use the no-AI test entry for all three cases, then create an event from a real fictional-letter interpretation. Inspect it in Calendar and cancel another creation.
  Commit: `Complete hackathon phone calendar acceptance`

- [ ] **3. Verify clone-and-run setup and finish the hackathon demo**
  Becomes usable: A new operator can clone the code, configure their own provider, run the relay and install the iPhone demo without an account/email service.
  Why now: Public reproducibility and a complete demo finish the narrowed scope.
  PRD ref: `prd.md > Data and Open-Source Experience`; `prd.md > Demonstration and Acceptance`.
  Spec ref: `spec.md > Where It Runs and How Someone Tries It`; `spec.md > External Services and Dependencies`; `spec.md > Verification and Build Sequence`.
  Build: Maintain secret-free setup examples and accurate README, retain the selected MIT license, resolve scoped final review findings and prepare the demo. No push/publication is performed merely by editing this checklist.
  Verify (mechanical): Check documented fresh-clone setup with separate operator-owned local configuration, correct Xcode signing and matching relay token. Verify no tracked credentials/personal letters; audit Git history before publishing. Check the complete four-step journey. Release compilation alone does not prove AI works in Release; document separate Debug/Prod configuration and accepted relay URLs.
  Learner check: Follow the README, run the end-to-end demo and report remaining confusing or broken behavior. Confirm the scoped demo is ready.
  Commit: `Prepare reproducible open-source hackathon demo`

## Hands-on Checkpoints

- [x] Early interpretation review completed; preserve accepted layout and feedback.
- [x] Final four-step journey and calendar results reviewed on one iPhone — learner confirmed the requested hands-on check passed; no detailed edge-case or target-user coverage is inferred.
- [x] Learner confirmed the requested fresh fictional-bill iPhone check passed: capture/import → fresh analysis; source-matching amount, payment requirement and deadline; reviewed event date and alert; newly saved Calendar event date, all-day/timed setting, alert and notes. This confirmation covers that bill flow; it does not establish both-language coverage, appointment duration/zone edge cases, actual notification delivery or fresh-operator setup.

No second phone, account isolation, email delivery or saved-conversation review is required.

## Appointment Extraction Follow-up

- [x] Carry linked appointment date/time/time-zone facts through validation and calendar proposal construction, with manual fallback for ambiguity.
- [ ] Re-run fresh fictional appointment letters through the configured live provider after restarting the relay. Check explicit AM/PM, multiple appointments, missing time/zone and source-grounded linkage in both languages.
- [ ] Verify extracted time and alert in a newly saved physical-phone event. Existing displayed analyses do not gain new time facts automatically.

## Duration Follow-up

- [x] Remove duplicate appointment time-zone display while retaining the editable picker.
- [x] Add a separate AI-suggested duration setting for timed appointments, bounded to 1–1,440 minutes, with a 30-minute fallback.
- [x] Replace +/− with a compact duration capsule opening hour/minute wheels and a visible end time; block invalid input without additional confirmation switches.
- [ ] Re-analyze fictional appointment letters with the restarted relay and verify duration suggestions are reasonable, clearly labeled, and absent from all-day actions.
- [ ] Verify hour/minute wheel selection (including 1 and 1,440 minutes) and end time on a newly saved physical-phone event, including a duration crossing midnight.

## UI, Usability and Accessibility Follow-up

- [x] Remove date/time-verification and overall-confirmation switches; allow valid prefilled events to save directly to Calendar and require entry only for missing date/time. The app’s Add button performs direct creation; no second review.

- [x] Implement the requested home/result styling, remove the decorative envelope logo and group calendar examples under Demo tools.
- [x] Add in-app notification presets, None and custom date/time; save alarms with the event without requiring confirmation switches.
- [x] Replace the home-screen “all edges visible” instruction with readable-text guidance consistent with the no-cropping requirement (English and Chinese; simulator build verified).
- [ ] Evaluate a concise action/event-date/notification-time summary and common-options-first alert selection; these are proposed refinements, not completed UI.
- [ ] Verify contrast, actual touch targets, Chinese wrapping and VoiceOver across the current screens.
- [ ] Check the Calendar permission dialog and whether users understand that Add saves immediately to their default calendar.
- [ ] On a phone, save new all-day and appointment events with presets, custom alerts and None; verify alarm times, notification delivery, date changes and time-zone behavior. Preserve previously saved events.
- [ ] Before making an independent-use suitability claim, observe representative users completing the fictional-letter flow without step-by-step coaching, including fluent English readers and users who prefer Chinese explanations, with varied ages, document familiarity and accessibility needs; record assistance and confusion about conditions, event dates, notification times and unsaved letters. This evidence is separate from learner demo approval.

## Final Review

- [ ] Try newly analyzed everyday and bank/credit-card statements on the phone, inspect balances/date roles in each selected app language and a saved reminder; account balances must not become payment requests, and paid/autopay cases must not request manual payment.

- [ ] Verify the all-day fix on a newly created phone event.
- [ ] Resolve scoped capture/analysis/calendar/setup feedback; record unresolved limitations accurately.
- [ ] Final review complete — learner explicitly confirms hackathon demo readiness.

## Code Tour and App Map

- [ ] Learning activity complete — concise capture → analysis → calendar walkthrough or equivalent prior practice.
- [ ] Optional transfer reflection offered/declined/completed; private reflections stay in ignored learner profile.
- [ ] `devpost/app-map.html` generated from actual code, checked and shown.

No completed learning wrap-up is inferred from the scope change. Keep it proportional to the smaller demo.

## Revisions

- Planning documents consolidate the approved billing/banking, selected-language, calendar-cutoff, alert and Test/Prod decisions into their relevant sections. Detailed edit history is available in Git. Current evidence and outstanding acceptance remain separate.

## Event Note Follow-up

- [x] Separate generated selected-language calendar notes from source/review copy and preview the exact note before Add. Preserve conditions, optionality, deadline cutoffs and uncertainty.
- [ ] Verify fresh live-provider notes for appointments, conditional actions and deadlines in both languages; check grounding and concise event wording.
- [x] Check the note on a newly saved phone event; existing events retain their old notes. Learner confirmed the newly saved fictional-bill event note matched the review on 2026-10-08; other action types and both-language live output remain pending above.

- Bill calendar follow-up: verify concise titles/notes in each selected app language with a fresh live interpretation, unique source excerpts and preserved explicit clock cutoffs. Screenshot-based deterministic regressions do not establish live provider output quality.

- [x] Restore editable dates and time-zone selection for all-day deadlines/reminders; default date-only items/appointments to the phone zone and timed cutoffs to their stated source zone; preserve displayed wall date/time on zone changes.
- [x] Carry bill type, organization and linked payment amount into calendar titles/notes, including generic or older AI responses. Preserve the original deadline when choosing another calendar date.
- [ ] Restart the relay and analyze a fresh fictional bill; verify summary, contextual calendar heading/notes, editable date/time-zone and the saved phone event. Existing saved events remain unchanged.

- [x] Use an in-page time-zone menu and compact date/time control on separate labeled rows, including editable personal reminders; remove the separate date-entry sheet.
