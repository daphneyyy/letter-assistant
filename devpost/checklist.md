---
doc: checklist
status: approved
---

# Letter Assistant — Hackathon Build Checklist

Build mode: Fast (retained). Scope revised directly by the learner on October 2, 2026: capture → local photo checks → analysis → creation in the iPhone calendar. No email, login, archive, chatbox or synchronization is required for the hackathon. New operators clone the source and supply their own API key. Previous planning/build history is preserved in `build-history.md`; its old resume instructions are not active.

## Current State

The core implementation and no-AI calendar test entry exist, with signed builds installed on the learner's iPhone. Early hands-on review is complete. Remaining boxes describe acceptance and release readiness, not permission to build the removed features.

Recorded evidence: 20 unit cases passed in the calendar checkpoint (that runner later hung and was stopped), three UI tests passed in a completed separate run, then the focused EventKit all-day regression test passed. Signed Debug and unsigned Release builds have passed. Backend checks previously passed 24 tests. No new code/test pass is claimed from this requirements-only revision. Actual phone confirmation of the all-day fix and broader final acceptance remain pending. Conditional enrollment extraction has improved in individual runs but is not broadly accepted.

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
  Build: Preserve manual reminder-date selection, verified appointment time/zone, conditions, source notes, explicit confirmation, editor callbacks and interrupted-result handling. Automatic urgency-based recommendations are not required. No calendar-reading, in-app calendar or sync work.
  Verify (mechanical): Use existing date-policy/EventKit tests and UI evidence; run targeted tests for subsequent fixes. On the iPhone check newly saved all-day events, appointment date/time/duration/zone, notes, alerts, cancel/Discard Changes, unavailable calendar and interrupted result. Do not silently alter previously saved events.
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
