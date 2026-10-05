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
- [x] Replace the home-screen “all edges visible” instruction with readable-text guidance consistent with the no-cropping requirement (English and Chinese; October 4 simulator build verified).
- [ ] Evaluate a concise action/event-date/notification-time summary and common-options-first alert selection; these are proposed refinements, not completed UI.
- [ ] Verify contrast, actual touch targets, Chinese wrapping and VoiceOver across the current screens.
- [ ] Check the Calendar permission dialog and whether users understand that Add saves immediately to their default calendar.
- [ ] On a phone, save new all-day and appointment events with presets, custom alerts and None; verify alarm times, notification delivery, date changes and time-zone behavior. Preserve previously saved events.
- [ ] Before making an independent-use suitability claim, observe target older adults completing the fictional-letter flow without step-by-step coaching; record assistance and confusion about conditions, event dates, notification times and unsaved letters. This evidence is separate from learner demo approval.

## Final Review

- [ ] Try newly analyzed everyday and bank/credit-card statements on the phone, inspect bilingual balances/date roles and a saved reminder; account balances must not become payment requests, and paid/autopay cases must not request manual payment.

- [ ] Verify the all-day fix on a newly created phone event.
- [ ] Resolve scoped capture/analysis/calendar/setup feedback; record unresolved limitations accurately.
- [ ] Final review complete — learner explicitly confirms hackathon demo readiness.

## Code Tour and App Map

- [ ] Learning activity complete — concise capture → analysis → calendar walkthrough or equivalent prior practice.
- [ ] Optional transfer reflection offered/declined/completed; private reflections stay in ignored learner profile.
- [ ] `devpost/app-map.html` generated from actual code, checked and shown.

No completed learning wrap-up is inferred from the scope change. Keep it proportional to the smaller demo.

## Revisions

- October 4 result-action follow-up: learner preferred the former end-reading/home-return control. Removed Photograph another letter from the result-page action list; restored the fixed-bottom Finish reading / 结束本次阅读 button and unsaved-letter confirmation, with Chinese confirmation 结束并返回首页. There is one result-page exit action. Updated PRD; simulator build passed. Phone layout remains to be reviewed after updating the app.

- October 4 duplicate result-action cleanup: removed the sticky Finish reading / 结束本次阅读 button and its separate alert/state. Photograph another letter / 拍摄另一封信 is the single result-page restart action and retains the unsaved-letter discard confirmation. Updated PRD journey; simulator build passed. No new UI test or phone acceptance is inferred.

- October 4 prompt simplification requested by the learner: reduced interpretationPrompt from 17,130 characters/2,402 whitespace-separated words to 8,525/1,109 (about half the characters). Merged repeated grounding/payment/date rules, removed schema-format repetition and bilingual examples, and replaced selected-language string substitutions with a direct output-language instruction. Preserved banking minimum/full-balance distinctions, paid/autopay handling, EOB responsibility/no-payment interpretation, conditions, appointment/time-zone evidence and separate duration estimates. Backend check/32 tests passed. Four fresh fictional responses passed source-role assertions: card minimum USD 35 by November 22 distinct from USD 1,200 balance; autopay no actions; conditional membership cancellation by November 25 distinct from December 1 renewal; EOB USD 50 responsibility with optional record keeping and no payment. No broad accuracy/speed improvement or physical-phone acceptance is inferred. No iOS code changed.

- October 4 removal of old online photo validation: deleted validationPrompt/image label, quality-result provider schema/type/validator, both provider validate methods, relay /validate-page endpoint and accepted-token storage/digests, and the unused iOS validation network methods/token payload. Only local phone readability checks precede /interpret. Updated transport/security/retry/multipage tests to the current local-readability request; a regression verifies removed endpoint 404 with zero provider calls. Backend type check/32 tests and iOS 46 unit tests passed. No new live-provider or physical-phone verification was performed for this removal.

- October 4 waiting-copy correction: replaced the stale bilingual-generation message with the explicit selected language name: English explanation / 中文解读. Checked both strings and searched runtime UI for remaining bilingual-generation wording. This is a text-only change; no additional simulator test was run.

- October 4 selected-app-language and analysis-error revision: interpretation requests carry the app language; both provider transports use schemas with only that language, retaining source excerpts and grounding checks. A local compatibility adapter copies selected text into legacy fields without generating a translation. Added app-language forwarding and both-transport English/Chinese schema regressions. Connection, timeout, busy and malformed/incomplete AI responses now have distinct messages; each request uses a fresh URLSession rather than shared pooled connections. Relay upload limit increased from 15 to 60 seconds with upload_timeout and safe error-code/status logs. On inspection no relay listener was present, consistent with immediate connection failure; it was restarted. The precise cause of the learner's later failure is not yet confirmed. Backend check/33 tests and iOS 46 unit tests passed. Fresh fictional English card and Chinese autopay responses were schema-valid in 21.3/17.6 seconds; card minimum remained USD 35 with November 22 deadline, autopay had no actions. Real-bank testing was withheld pending explicit external-processing authorization after automatic approval review rejected it. An actual relay request with two fictional autopay pages returned HTTP 200/banking/five facts/no actions in 16.9 seconds. Physical-device first-tap/retry acceptance remains open.

- October 4 learner-requested bank-statement expansion: added banking domain for deposit/checking/savings and credit-card statements, including informational statements with no matching category. Account balances/transactions are source facts rather than amounts due; minimum card payment stays separate from statement balance, and closing dates stay separate from payment deadlines. Updated bilingual headings/unsupported copy, calendar context, scope/PRD/spec/README and three fictional fixtures. Backend type check and 31 tests passed; iOS 45 unit tests passed. Three fresh configured-provider responses were reviewed in both languages and asserted: checking balance USD 1100 with no actions; card balance USD 1200 with required minimum USD 35 by November 22, not October 31; scheduled full-balance autopay with no actions. These fictional cases do not verify the learner’s real bank statement or physical-phone behavior; restart relay, reinstall and reanalyze for acceptance. This revision supersedes the earlier banking exclusion. Investment/retirement remain outside scope.

- October 4 learner-approved expansion: everyday bills/fee and renewal notices now share the capture → bilingual analysis → reviewed calendar flow. Added billing domain, ordinary-bill headings/calendar context, broader app copy and five fictional fixtures; updated scope/PRD/spec/README. No accounts, bill payments, automatic cancellation, recurring events or archive features were added. Banking account statements, investment/retirement and non-health insurance policy documents remain outside scope.
- Expansion verification: backend type check and 30 tests passed; iOS 44 unit tests passed, followed by a successful final simulator build after welcome-copy editing. Six fresh live responses were reviewed in both languages: electricity linked USD 84.20 (not USD 120 gross charges) to November 20; telephone autopay and paid internet receipt had no actions; membership cancellation stayed conditional with November 25 cutoff distinct from December 1 renewal; an undated internet payment retained null deadline; existing EOB behavior retained optional record keeping without a payment task. Response expectations were also asserted locally. These individual fictional cases do not establish universal bill accuracy or real-phone acceptance. Existing results require fresh analysis after restarting the relay.

- October 4 latency feedback: two fictional bill pages with the configured model took 28,334 ms before request deduplication and 27,932 ms after; both returned schema-valid interpretations (five facts, one action). Input tokens fell from 12,267 to 11,315 by removing the redundant schema copy from the OpenAI system message while retaining strict response_format and output validation. These single runs show no meaningful latency gain and do not evaluate the learner’s real letter. No model switch or image downsampling was made. Added actual elapsed waiting seconds and explanatory English/Chinese copy after 20 seconds, without invented completion percentages. Backend check/29 tests and iOS 43 unit tests passed. Physical-device waiting UI and broader live extraction acceptance remain open.

- October 4 follow-up: restored the calendar-save confirmation label to Back to result / 返回解读结果 at the learner’s request; synchronized its accessibility identifier, existing UI assertion and PRD/spec. This is a text-only reversal; navigation and the compact duration picker are unchanged. Verified the diff and matching strings; no new simulator or phone test was run.

- October 4 real-upload correction: removed unconditional fictional-letter wording from both provider transports and shared grounding. Fictional/test/sample labels now require explicit visible source evidence in both languages, including calendar notes. Backend type check and all 29 tests passed, with outgoing-request coverage for both transports. No private document was used for this verification; the uploaded real-letter result must be regenerated to assess the live correction.

- October 4 button styling correction: learner clarified that only the Not now / 暂不添加 text should change color. Removed the mint background, border and expanded button layout; restored the original cancel button with teal text. Simulator build passed. Phone appearance awaits reinstall/review.

- October 4 UI feedback: replaced always-visible duration wheels with a compact current-value capsule; tapping opens hour/minute wheels in a popover and dismissal retains the value. The 1–1,440-minute range, AI/default initialization, zero-duration validation and end-time calculation remain. Renamed calendar-save confirmation Back to result / 返回解读结果 to Back to home / 返回首页 as requested. The two focused simulator UI tests passed together, covering hidden/open/closed/reopened wheels, retained selection, zero and 24-hour behavior, end-time presence and confirmation return. The first duration run failed only because its end-time assertion did not scroll to the offscreen form row; the revised test checks that row after scrolling. No physical-phone installation or acceptance is inferred.

- October 4 resumed build: corrected English/Chinese capture guidance to ask for readable text. Backend type check and 29 tests passed; the iPhone 17 Pro / iOS 26.5 simulator unit run passed 43 tests with zero failures. No new physical-device installation or UI test run was performed.
- October 4 live-provider checks: one fresh enrollment response preserved conditional plan change, November 15 deadline, January 1 coverage start and optional October 20 session without inventing its time; one EOB response preserved USD 200 billed / USD 150 paid / USD 50 responsibility, optional record keeping and no payment request; one informational result response returned no actions/deadline without asserting no action is needed. Both languages were reviewed against fictional source expectations. These individual responses predate the classification-wording prompt correction and do not establish broad extraction reliability.
- October 4 evaluation repair: the no-deadline fixture said only “insurance,” so its unsupported result was consistent with the health-insurance scope. Clarified the fixture title/organization to explicitly say health insurance, retaining the address-confirmation request and absence of a deadline. Its first rerun extracted the call correctly but exposed irrelevant archive-category wording in both summaries; corrected the prompt to keep classification metadata out of reader-facing copy. No wire schema or product scope changed. A fresh response after the prompt correction extracted the address-confirmation call with no deadline, retained the fictional warning and omitted classification/archive wording in English and Chinese; backend type check and all 29 tests passed again. Physical capture/retake, broader extraction cases and learner acceptance remain open.

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

- [x] Restore editable dates and time-zone selection for all-day deadlines/reminders; default date-only items/appointments to the phone zone and timed cutoffs to their stated source zone; preserve displayed wall date/time on zone changes.
- [x] Carry bill type, organization and linked payment amount into calendar titles/notes, including generic or older AI responses. Preserve the original deadline when choosing another calendar date.
- [ ] Restart the relay and analyze a fresh fictional bill; verify summary, contextual calendar heading/notes, editable date/time-zone and the saved phone event. Existing saved events remain unchanged.

- [x] Use an in-page time-zone menu and compact date/time control alongside the label, including missing-date reminders; remove the separate date-entry sheet.

- October 4 repayment/cutoff correction: credit-card calendar reminders use confirmed full statement balance in the title, with source-required minimum separately labeled in notes and unchanged source action semantics. Added nullable balance/time/zone metadata and compatibility for older responses. Explicit clock deadlines become timed cutoff markers in the stated zone, with early-alert guidance; date-only deadlines remain all-day. Added a fictional card fixture and regression coverage for balance selection, 20:00 Eastern → 17:00 Pacific on November 15, timezone preservation and EventKit all-day flags. Backend type check and 33 tests passed; all 47 iOS unit tests passed on the iPhone 17 Pro / iOS 26.5 simulator. One fresh Chinese fictional AI response correctly linked full balance USD 2,093.02 separately from required minimum USD 35 and returned the conditional November 15 20:00 America/New_York cutoff (30,712 ms). Physical-phone saved-event and notification acceptance remain open.

- October 4 token optimization: compact selected-language provider strings/summary; relay supplies schema_version and fact origin, expands shared source_ids and restores the unchanged client contract. Exact same-page quotes deduplicate; differing pages/quotes remain distinct. Backend type check and all 37 tests passed, including both transports/languages, evidence-index rejection, preserved fields, balance/minimum/cutoff metadata, appointment duration and empty/unsupported behavior. Live fictional card, telephone-autopay and EOB cases passed; final card retained full balance USD 2,093.02, required minimum USD 35, October 14 payment deadline and conditional November 15 20:00 America/New_York call. On the same fictional card/model, old input/output usage was 6,354/2,077 and final compact usage 6,329/1,805 (about 0.4%/13.1% lower); single-run variation does not establish a universal saving or latency gain. No images/model/output-token limit/iOS code changed. Physical-device acceptance remains open.
