---
doc: checklist
status: approved
---

# Letter Assistant — Hackathon Build Checklist

Build mode: Fast (retained). Scope revised directly by the learner on October 2, 2026: capture → local photo checks → analysis → creation in the iPhone calendar. No email, login, archive, chatbox or synchronization is required for the hackathon. New operators clone the source and supply their own API key. Previous planning/build history is preserved in `build-history.md`; its old resume instructions are not active.

## Current State

The core implementation and no-AI calendar test entry exist, with signed builds installed on the learner's iPhone. Early hands-on review is complete. Remaining boxes describe acceptance and release readiness, not permission to build the removed features.

Historical evidence: 20 unit cases passed in the calendar checkpoint (that runner later hung and was stopped), three UI tests passed in a completed separate run, then the focused EventKit all-day regression test passed. Signed Debug and unsigned Release builds have passed. Backend checks previously passed 24 tests. Those results predate the latest UI/alert refinements. Actual phone confirmation of the all-day fix and broader final acceptance remain pending. Conditional enrollment extraction has improved in individual runs but is not broadly accepted.

Latest October 2 follow-up: the UI refinements, logo removal and expanded preset/custom alerts are implemented. The expanded-alert run reported 24 passing unit tests. A subsequent UI run passed the existing three UI cases; the new custom-picker test initially failed to locate its unlabeled date control. After adding a stable accessibility identifier, a focused custom-picker run completed with TEST SUCCEEDED. The four UI cases therefore have passing evidence across separate runs, not one final all-green combined run. Large-text cancel-button scrolling was also corrected in the test. No latest-refinement physical-device installation, notification delivery, target-user study or live AI accuracy pass is established by these simulator results. This documentation update runs no new app tests.

## Slices

- [ ] **1. Close capture, local photo checks and real analysis acceptance**
  Becomes usable: Photograph one or multiple pages, handle readability/retakes and read a grounded bilingual interpretation without logging in.
  Why now: Core implementation exists; complete the remaining real-use evidence before declaring the demo ready.
  PRD ref: `prd.md > Page Capture and Validation`; `prd.md > Actionable Explanation`; `prd.md > Recovery Behavior`.
  Spec ref: `spec.md > Capture and Page Validation`; `spec.md > Letter Interpretation and Grounding`; `spec.md > Look and Feel`.
  Build: Preserve the native camera, local-only check, Use anyway for uncertain quality, page order, four-section explanation and retries. Fix only relevant acceptance failures; no account/archive work.
  Verify (mechanical): Run checks appropriate to actual fixes. Compare real fictional provider output against expected source facts, including conditional actions, EOB/no-action/no-deadline cases and both languages. Record any provider quota blocker honestly. Verify physical capture/retake and basic accessibility without inferring coverage from a general approval.
  Learner check: Capture a fictional letter, retake an unreadable page, try an uncertain image and inspect the explanation/source details. Confirm English/Chinese readability and guidance.
  Commit: `Complete hackathon capture and analysis acceptance`

- [ ] **2. Close creation-only phone calendar acceptance**
  Becomes usable: Review an action and save a correct all-day deadline/reminder or timed appointment in the phone calendar.
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
  Build: Maintain secret-free setup examples and accurate README, select an open-source license before publication, resolve scoped final review findings and prepare the demo. No push/publication is performed merely by editing this checklist.
  Verify (mechanical): Check documented fresh-clone setup with separate operator-owned local configuration, correct Xcode signing and matching relay token. Verify no tracked credentials/personal letters; audit Git history before publishing. Check the complete four-step journey. Release compilation alone does not prove AI works in Release; document Debug-only relay support.
  Learner check: Follow the README, run the end-to-end demo and report remaining confusing or broken behavior. Confirm the scoped demo is ready.
  Commit: `Prepare reproducible open-source hackathon demo`

## Hands-on Checkpoints

- [x] Early interpretation review completed; preserve accepted layout and feedback.
- [ ] Final four-step journey and calendar results reviewed on one iPhone.

No second phone, account isolation, email delivery or saved-conversation review is required.

## Appointment Extraction Follow-up

- [x] Carry linked appointment date/time/time-zone facts through validation and calendar proposal construction, with manual fallback for ambiguity.
- [ ] Re-run fresh fictional appointment letters through the configured live provider after restarting the relay. Check explicit AM/PM, multiple appointments, missing time/zone and source-grounded linkage in both languages.
- [ ] Verify extracted time and alert in a newly saved physical-phone event. Existing displayed analyses do not gain new time facts automatically.

## Duration Follow-up

- [x] Remove duplicate appointment time-zone display while retaining the editable picker.
- [x] Add a separate AI-suggested duration setting for timed events, bounded to 1–1,440 minutes, with a 30-minute fallback.
- [x] Replace +/− with presets/custom minutes and a visible end time; block invalid input without additional confirmation switches.
- [ ] Re-analyze fictional appointment letters with the restarted relay and verify duration suggestions are reasonable, clearly labeled, and absent from all-day actions.
- [ ] Verify preset/custom duration and end time on a newly saved physical-phone event, including a duration crossing midnight.

## UI and Older-Adult Usability Follow-up

- [x] Remove date/time-verification and overall-confirmation switches; allow valid prefilled events to open Calendar directly and require entry only for missing date/time. The app’s Add button performs direct creation; no second review.

- [x] Implement the requested home/result styling, remove the decorative envelope logo and group calendar examples under Demo tools.
- [x] Add in-app notification presets, None and custom date/time; save alarms with the event without requiring confirmation switches.
- [ ] Replace the home-screen “all edges visible” instruction with readable-text guidance consistent with the no-cropping requirement.
- [ ] Evaluate a concise action/event-date/notification-time summary and common-options-first alert selection; these are proposed refinements, not completed UI.
- [ ] Verify contrast, actual touch targets, Chinese wrapping and VoiceOver across the current screens.
- [ ] Check the Calendar permission dialog and whether users understand that Add saves immediately to their default calendar.
- [ ] On a phone, save new all-day and appointment events with presets, custom alerts and None; verify alarm times, notification delivery, date changes and time-zone behavior. Preserve previously saved events.
- [ ] Before making an independent-use suitability claim, observe target older adults completing the fictional-letter flow without step-by-step coaching; record assistance and confusion about conditions, event dates, notification times and unsaved letters. This evidence is separate from learner demo approval.

## Final Review

- [ ] Verify the all-day fix on a newly created phone event.
- [ ] Resolve scoped capture/analysis/calendar/setup feedback; record unresolved limitations accurately.
- [ ] Final review complete — learner explicitly confirms hackathon demo readiness.

## Code Tour and App Map

- [ ] Learning activity complete — concise capture → analysis → calendar walkthrough or equivalent prior practice.
- [ ] Optional transfer reflection offered/declined/completed; private reflections stay in ignored learner profile.
- [ ] `devpost/app-map.html` generated from actual code, checked and shown.

No completed learning wrap-up is inferred from the scope change. Keep it proportional to the smaller demo.

## Revisions

- October 2: learner explicitly removed email/accounts, cloud archive and chat from hackathon delivery. In-app calendar/phone sync, login, chatbox and saved letter/extracted/question/added-item summaries are future commercial scope.
- Clone-and-run with each operator's own API key is the distribution target. Preserve the current local relay; no in-app key entry or hosted service was requested.
- Automatic urgency-based reminder suggestions and physical cross-device acceptance are not required by the four-step demo. User-selected dates remain available.
- Prior detailed evidence and superseded requirements are retained in `build-history.md` and Git history. Unchecked removed features are deferred, not falsely marked completed.

- October 2 follow-up: learner added letter classification to the future commercial roadmap. A user-facing classification/organization feature is not part of hackathon acceptance; existing analysis classification metadata does not count as that future feature being implemented.

- October 2 follow-up: learner added multilingual support to the future commercial roadmap. Additional languages and source-letter/UI/explanation/speech coverage remain to be defined. Hackathon language scope stays English-letter input with English/Chinese interface and explanations.

- October 2 UI/alert follow-up: synchronized current UI and notification options with PRD/spec, retained open real-phone and AI accuracy checks, and added explicit older-adult usability review items. This documentation revision does not implement the proposed form simplification or mark target-user acceptance complete.

- Direct-save follow-up: verify first-use write-only permission, denial/recovery via Settings, missing default calendar, actual saved events and notification delivery on a physical phone. Injected unit/UI writer tests do not prove real Calendar writes.


## Event Note Follow-up

- [x] Separate generated bilingual calendar notes from source/review copy and preview the exact note before Add. Preserve conditions, optionality, deadline cutoffs and uncertainty.
- [ ] Verify fresh live-provider notes for appointments, conditional actions and deadlines in both languages; check grounding and concise event wording.
- [ ] Check the note on a newly saved phone event; existing events retain their old notes.

- Bill calendar follow-up: verify concise bilingual titles/notes with a fresh live interpretation, unique source excerpts and preserved explicit clock cutoffs. Screenshot-based deterministic regressions do not establish live provider output quality.

- [x] Restore editable dates and time-zone selection for all-day deadlines/reminders; default every review to the phone zone and preserve displayed wall date/time on zone changes.
- [x] Carry bill type, organization and linked payment amount into calendar titles/notes, including generic or older AI responses. Preserve the original deadline when choosing another calendar date.
- [ ] Restart the relay and analyze a fresh fictional bill; verify summary, contextual calendar heading/notes, editable date/time-zone and the saved phone event. Existing saved events remain unchanged.
