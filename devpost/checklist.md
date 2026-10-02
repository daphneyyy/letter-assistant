---
doc: checklist
status: approved
---

# Letter Assistant — Build Checklist

Build mode: Fast (chosen October 1, 2026). Verify and commit each slice with concise explanations; pause for early hands-on feedback after slice 1 and final review.

## Before Implementation

Scope, PRD, and spec retain approved status with the learner's explicit V1 simplifications recorded. Slice 1 implementation is in progress; no slice is marked complete. The learner approved this revised checklist on October 1, 2026.

- Authentication is email-only: signup, email verification, email-and-password login, and password recovery by email. Phone-number/SMS authentication is deferred.
- Calendar support is creation-only: review and confirm a letter-generated event, then save it in the iPhone calendar. Later changes are managed there. No Calendar tab, bidirectional editing, cross-device calendar synchronization, event reconciliation, or calendar conflict handling.
- Exactly five categories: Bills, Insurance explanations, Appointments, Test results, and Medications. Needs review is a classification state, not a sixth category. Unknown person is a recipient fallback, not a category.
- Accessibility starts in slice 1 and continues in every visible slice: large Dynamic Type, readable wrapping Chinese text, large tap targets (at least 44 points), and basic VoiceOver support.
- Use one physical iPhone for capture and text-to-speech guidance (slice 1), speech-to-text voice questions (slice 4), email callbacks, and calendar checks as those features arrive. Test account isolation with two accounts/API clients without requiring two phones. Validate cross-device archive and conversation behavior once during final acceptance; no cross-device calendar behavior is required.

The learner authorized a separate project-local Git repository on October 1, 2026; it has been initialized on `codex/letter-assistant`. Do not alter the parent index or sibling work. Preserve ignore rules for `/devpost/learner-profile.md`, `.env`, `.env.*` (allow a secret-free `.env.example`), local Xcode/debug configuration, captures, credentials, and build output. Inspect tracked files and each intended staged diff; commit only reviewed project changes.

For slice 1, verify Xcode/signing, one iPhone, OpenRouter free vision access, and the protected local development relay described in the spec. Supabase accounts/storage and email delivery are prerequisites for slice 2, not the first milestone. Verify English/Mandarin text-to-speech capture guidance in slice 1, speech-to-text voice-question transcription in slice 4, and the calendar editor when calendar creation is added. Use fictional letters. No purchases or exact spending budget are authorized; record unavailable integrations as blockers rather than passed checks.

## Slices

- [ ] **1. Capture one fictional letter and get a real, accessible AI interpretation**
  Becomes usable: Photograph one fictional single-page letter, validate or retake the photo, and read a real AI interpretation showing What this is / What to do / When, in that order, in English or Chinese.
  Why now: Proves the core product value and image/AI risk before accounts, archive persistence, or secondary features can delay feedback. Bootstrapping is part of this usable flow.
  PRD ref: `prd.md > The Core Journey`; `prd.md > Page Capture and Validation`; `prd.md > Actionable Explanation and Voice Questions`; `prd.md > Look and Feel`.
  Spec ref: `spec.md > Core Interpretation Milestone Before Accounts`; `spec.md > Stack`; `spec.md > Capture and Page Validation`; `spec.md > Letter Interpretation and Grounding`; `spec.md > Look and Feel`.
  Build: Create the Xcode app/test scheme, camera/retake flow with system text-to-speech spoken guidance (no voice-question recording or transcription yet), temporary page state, language selection, and real validation/interpretation through the protected local development relay. Reuse the future backend's structured AI contracts and grounding modules; keep provider secrets off the phone. Display source-grounded type, action, and timing, with explicit missing/uncertain fields and retry states. Include large Dynamic Type, wrapping Chinese text, 44-point tap targets, and VoiceOver labels, reading order, and processing/error announcements from the start. Create fictional fixtures with hand-checked expected facts. No user authentication, archive, SMTP, database, or calendar setup in this milestone.
  Verify (mechanical): Build and run focused capture/contract checks on an installed simulator; record working commands and relay setup in README. On one physical iPhone capture a fixture, reject a blurry/cropped page, retake it, and obtain a real AI result. Verify English/Mandarin text-to-speech capture instructions and spoken retake reasons. Compare both languages against expected amounts, actions, dates and evidence; include missing-action, missing-deadline, and uncertain-field fixtures. Test validation/AI failure and retry without claiming a save. Inspect large accessibility text sizes, long Chinese text, tap targets and the core VoiceOver path. Confirm no provider key in the app and no public unauthenticated endpoint. Mocks do not establish AI success.
  Learner check: Run the app on one iPhone, choose a language, photograph a fictional letter, and retake an unclear photo. Read What this is / What to do / When. Try larger text and VoiceOver; describe what feels clear or confusing. This milestone does not save letters across launches.
  Commit: `Add accessible single-letter capture validation and real AI interpretation`

- [ ] **2. Use email-only accounts and reopen a privately saved letter**
  Becomes usable: Sign up, verify an email address, log in, recover a password by email, and reopen the interpreted single-page letter and original photo after relaunch.
  Why now: Adds account ownership and persistence to the already-proven core flow without combining them with multi-page organization.
  PRD ref: `prd.md > Account and Cross-Phone Archive Access`; `prd.md > Letter Detail Summary`; `prd.md > Recipient and Letter Archive`; `prd.md > Recovery Behavior`.
  Spec ref: `spec.md > App Shell, Account, and Language`; `spec.md > Backend Authorization, Operations, and Recovery`; `spec.md > Data Model`; `spec.md > External Services and Dependencies`; `spec.md > Where It Runs and How Someone Tries It`.
  Build: Configure Supabase and verified email delivery, pin the relevant dependencies, create migrations and private storage, and replace the development relay transport with verified-user backend calls. Add Keychain-backed email/password sessions, email verification and reset callbacks, language profile, Chat/Archive shell, stable request IDs, validated original uploads and atomic interpretation/initial-message/archive save. Provide minimal saved-letter/detail/photo access and retry states. Disable the development-only path in release builds. Preserve slice 1 accessibility throughout account and archive screens. No phone-number authentication.
  Verify (mechanical): Compile and run focused backend/database checks; apply migrations only to the inspected dedicated target. On the same iPhone verify signup, verification, login, email recovery, cold-start/expired callbacks, logout and relaunch. Reopen a saved letter/photo. Check unverified access rejection, atomic save, idempotent retries, account-switch cache clearing, and direct row/photo isolation with two accounts or API clients. Verify accessible auth/detail screens. No second physical phone is required here.
  Learner check: Create and verify an email account, photograph a fictional letter, reopen it and its original photo after restarting, then recover your password through email and reopen the same archive.
  Commit: `Add email-only accounts and private single-letter archive`

- [ ] **3. Capture multi-page letters and organize the archive**
  Becomes usable: Capture a complete multi-page letter with per-page retakes, browse by recipient and category, correct filing, switch language, and reopen ordered original photos.
  Why now: Extends verified capture and persistence to complete letters and useful browsing before adding conversation.
  PRD ref: `prd.md > Page Capture and Validation`; `prd.md > Recipient and Letter Archive`; `prd.md > Actionable Explanation and Voice Questions`.
  Spec ref: `spec.md > Capture and Page Validation`; `spec.md > Private Archive and Letter Detail`; `spec.md > Data Model`; `spec.md > App-to-backend contract`; `spec.md > Important Failure Modes`.
  Build: Preserve accepted pages and their order, replace only the retaken page, ensure uploaded originals match the validated photos, and reject incomplete or altered page sets before interpretation. Use the stable page IDs, frozen manifests, SHA-256 checks, and page/size limits explicitly required by `spec.md > Capture and Page Validation` and `spec.md > App-to-backend contract`; leave mechanisms not prescribed there to implementation. Add the five categories, date sorting, recipient/category corrections, paged original-photo viewing, language changes, and foreground/manual refresh. Model Needs review separately as a classification state and Unknown person as a recipient fallback. Preserve no-action letters. Retain archive revision checks and accessible layouts; these are unrelated to deferred calendar conflict handling.
  Verify (mechanical): Test that retakes preserve other accepted pages, incomplete uploads or mismatched photo content/order cannot reach interpretation, and retries do not duplicate letters; include the spec-mandated hash/manifest checks. Evaluate real multi-page, no-action, ambiguous-category and missing-recipient fixtures. Verify exactly five categories, both fallback states, date sorting, corrections after relaunch/refresh, stable facts across language changes, readable originals, and accessibility. Verify server persistence and isolation using one phone and API clients; defer the physical cross-device demonstration to final acceptance.
  Learner check: Photograph a multi-page letter, retake one page, and inspect photo order. Correct recipient/category and switch language. Try an ambiguous category and an unknown recipient; verify neither appears as an extra category.
  Commit: `Add multi-page capture and recipient-based archive organization`

- [ ] **4. Ask spoken questions and resume each letter's conversation**
  Becomes usable: Ask a question about a letter, receive a grounded answer, view an updated detail summary, and resume the complete conversation after relaunch.
  Why now: Builds on stable letter identity, source evidence and persistence so questions stay attached to the correct letter.
  PRD ref: `prd.md > Actionable Explanation and Voice Questions`; `prd.md > Letter Detail Summary`; `prd.md > Recovery Behavior`.
  Spec ref: `spec.md > Voice Questions and Persistent Conversations`; `spec.md > Letter Interpretation and Grounding`; `spec.md > Backend Authorization, Operations, and Recovery`; `spec.md > Fact and action contracts`.
  Build: Add accessible Ask/Stop controls, English/Mandarin speech-to-text transcription of voice questions, recognized text, one-time submission and recovery. Implement grounded answers, explicit unanswerable responses, evidence/origin labels, persistent paginated history, bounded model context and atomic persistence of the assistant reply with both English/Chinese detail-summary versions, as explicitly required by `spec.md > Voice Questions and Persistent Conversations` and `spec.md > Fact and action contracts`. Serialize requests per letter and retry without duplication. Preserve original facts and filing corrections.
  Verify (mechanical): On one iPhone test real speech-to-text voice-question transcription in both languages, silence, denied microphone/speech-recognition permission, interruption and single submission. Evaluate answerable/unanswerable and user-statement fixtures without invented facts or cross-letter context. Test long-history pagination, context compression, concurrent API requests, failed-save retries and summary revisions. Relaunch and resume full history; check Dynamic Type, Chinese layout and VoiceOver. Physical cross-device conversation acceptance occurs once in slice 6.
  Learner check: Ask one spoken question the letter answers and one it cannot answer. Review the summary, restart the app, and resume the same letter's conversation.
  Commit: `Add grounded voice questions and persistent letter conversations`

- [ ] **5. Review and confirm a letter event for the iPhone calendar**
  Becomes usable: Review a letter-generated deadline, appointment, or clearly labeled reminder proposal; confirm and save it in the iPhone calendar. Manage later changes in the system calendar.
  Why now: Uses the proven letter facts and action flow while keeping calendar support limited to creation.
  PRD ref: `prd.md > External Calendar Handoff`; `prd.md > States and Boundaries`; `prd.md > Recovery Behavior`.
  Spec ref: `spec.md > Calendar Handoff and Reminder Suggestions`; `spec.md > Fact and action contracts`; `spec.md > Important Failure Modes`.
  Build: Implement date-policy rules, source/date review, confirmation, uncertain-date entry, past-date labels, timezone confirmation, editable proposed appointment duration, and midnight recheck. Present the system creation editor and handle saved/canceled/unknown outcomes honestly. Keep alert settings in that editor, later edits in the system calendar, and original letter facts unchanged. No Calendar tab, broad calendar reading, linked-event storage, bidirectional editing, reconciliation, calendar conflict handling, or cross-device calendar synchronization.
  Verify (mechanical): Run date-policy tests for reminder ranges, uncertainty, weekends, daylight-saving boundaries, all-day dates, past dates and midnight rollover. On one iPhone test deadline, no-deadline action, appointment, decline, save, cancel, unavailable editor and unknown outcome. Inspect the created event's dates/notes and alert controls. Verify no creation before confirmation, no automatic retry after unknown results, and accessible review UI. No second-phone calendar test.
  Learner check: Try letters with a deadline, without a deadline, and with an appointment. Review and confirm an event, inspect it in the iPhone calendar, and make later changes there. Cancel one creation and verify the app reports the outcome correctly.
  Commit: `Add confirmed creation-only iPhone calendar handoff`

- [ ] **6. Complete recovery checks and final cross-device acceptance**
  Becomes usable: The integrated app supports the complete journey with clear recovery and honest outcomes; one final cross-device check establishes archive and conversation continuity.
  Why now: Tests interactions among the completed features and cross-device behavior once, after there is a full journey to validate.
  PRD ref: `prd.md > Demonstration and Acceptance` (all ten scenarios); `prd.md > Recovery Behavior`; `prd.md > States and Boundaries`.
  Spec ref: `spec.md > Important Failure Modes`; `spec.md > Backend Authorization, Operations, and Recovery`; `spec.md > Verification and Build Sequence`; `spec.md > Look and Feel`; `spec.md > Recording and repository`.
  Build: Fix integration gaps in empty, processing, offline, timeout, quota, auth-expiry and save-retry states. Verify protected capture cleanup and draft recovery. Complete setup/demo instructions and acceptance evidence. Regress the accessibility implemented from slice 1; do not defer its implementation here.
  Verify (mechanical): Run focused Swift/backend/database checks and all ten PRD scenarios. Inject provider refusal/malformed output, offline/timeouts, save failure, duplicate requests, lease expiry and account changes. Check retained prior data, no false success, no duplicate application writes, and no cross-account leakage. Once during final acceptance, sign into the same account on a second physical iPhone and verify archive, original photos, filing corrections, language preferences and full conversation/updated summary; verify a separate account cannot access them. Do not test or claim cross-device calendar synchronization. Regress large Dynamic Type, readable Chinese, tap targets and VoiceOver across the core journey. If the second phone is unavailable, record that final acceptance is incomplete without blocking earlier slices or substituting simulator evidence for a two-phone pass.
  Learner check: Explore signup, capture, interpretation, archive, questions and calendar creation; try offline and cancel paths. Perform the single final two-phone archive/conversation check, then report what is broken, confusing or worth changing.
  Commit: `Complete recovery accessibility regression and final acceptance`

## Hands-on Checkpoints

- [x] Early core interpretation explored — after slice 1, before authentication and persistence; record feedback on usefulness, clarity, Chinese readability and accessibility.
- [ ] Final kick-the-tires exploration and feedback completed — after slice 6, including the single cross-device archive/conversation check; this also supplies final-review feedback.

Learn mode uses each slice's learner check before its commit. Fast mode retains the early and final checkpoints. No second physical iPhone is needed before final acceptance.

## Final Review

- [ ] Final review complete — feedback resolved and learner confirms ready to ship

Record concrete findings and agreed revisions here as unchecked tasks. Early feedback is recorded below; final whole-product readiness has not been confirmed.

## Code Tour and App Map

- [ ] Learning activity complete — guided route, focused alternative, prior practice connected, or brief recap
- [ ] Optional edit and transfer reflection addressed — offered/declined/already covered/not applicable as appropriate
- [ ] `devpost/app-map.html` generated from finished code, checked, and shown, including a project-grounded practice to reuse

Activity and evidence: Not started. Default to following capture → interpretation → saved detail through 2–3 actual code locations after final revisions; build-time practice may count.
Route and stops: Choose from actual completed code; no route has been presented.
Edit outcome: Not offered yet.
Reflection: Not offered yet; any personal response belongs only in the ignored learner profile.
Activity mode: To be recorded when performed.

## Build Evidence and Next Resume

October 1, 2026 — fast mode, slice 1 remains unchecked.

Implemented: dependency-free native Xcode app/shared scheme; single-page camera and retake controls; orientation/metadata normalization; local text/readability checks; English/Mandarin text-to-speech guidance; large Dynamic Type, wrapping Chinese UI, 44-point-plus controls and VoiceOver labels/announcements; real Responses API adapter behind a token-protected local relay; same-photo validation gate; memory-only results, retries, and source facts; four fictional fixtures and expected facts. Added setup and run instructions in README. No slice 2 features have been started.

Evidence: Debug simulator build passed. Seven focused iOS tests and one Chinese large-text UI test passed on iPhone 17 Pro / iOS 26.5 simulator; the screenshot was visually checked. Eight Deno tests and typecheck passed (isolated fake providers, not live extraction). A real local HTTP request with a fictional JPEG returned the expected 503 provider_not_configured with no API key. Ignore checks confirm learner profile and local credentials/config are excluded. Release simulator build also passed and contains no Debug.local.plist; the seven unit tests passed again after a language-switch error-message fix.

Pending acceptance: OpenRouter has confirmed the local key is valid and the account is on its free tier. The earlier OpenAI 401 was caused by sending an OpenRouter key to the wrong provider. The fictional bill passed live validation and interpretation through the local relay (HTTP 200 for each), with USD 125.00 and 2026-11-15 correctly extracted in both languages; remaining fixture cases are pending; no physical iPhone is connected. User plans to test on iPhone 18 Pro. Physical capture/retake, English/Mandarin audio and VoiceOver, and learner early feedback remain unverified. Do not tick or commit the completed-slice checkpoint until these checks and early feedback are complete.

Resume: configure OPENROUTER_API_KEY in ignored .env.local (never in chat or the phone bundle), start the relay per README, connect the test iPhone and set Xcode signing/private LAN address, then complete slice 1's real checks and early learner review. Do not ask again for build order, fast mode, or project-local Git initialization.

## Revisions

- Superseded the earlier in-app calendar proposal at the learner's explicit request. V1 creates confirmed letter-generated events only; later edits live in the system calendar. Removed calendar linking, synchronization, reconciliation and conflict work from all slices.
- Split the former first slice into accessible core capture/validation/real interpretation, then email-only accounts and private single-letter persistence. A protected local development relay proves real AI before account infrastructure; it is excluded from the release path.
- Retained the sequence core interpretation → accounts/archive → multi-page archive → conversation → calendar creation → recovery. Clarified the five-category boundary and the distinct meanings of Needs review and Unknown person.
- Made accessibility an implementation and verification requirement from slice 1 onward. Consolidated physical cross-device archive/conversation verification into final acceptance, with one-phone/API checks earlier.
- Aligned scope, PRD and spec with this explicit revision. The checklist remains draft; no implementation or verification is claimed complete.

- October 1, 2026: The learner explicitly approved the revised checklist, including its final wording refinements. Build order is approved; project-local Git initialization was subsequently authorized and completed.

- October 1, 2026: Learner chose to preview the existing Swift app in the Xcode iPhone simulator first. This is an interim UI preview; live AI and physical-camera acceptance remain pending, and the approved stack/build order are unchanged.

- Simulator sample troubleshooting: confirmed the local relay and token work; OpenAI rejected the configured credential. Replaced the misleading generic connection error with a specific bilingual invalid-key message that retains the photo and permits retry after updating local settings and restarting the relay. No credential values were logged or changed.

- October 1 provider correction: the learner clarified that the configured key is from OpenRouter with free API access. Switched the active integration to a pinned free vision model, zero input/output price ceilings, and no paid fallback; updated setup/spec without changing scope or build order. Read-only OpenRouter authentication succeeded (HTTP 200).

- OpenRouter adapter verification: eleven Deno tests and typecheck pass; eight iOS unit tests pass after adding a bilingual request-limit message. Live free-model photo validation succeeded. An interpretation with inconsistent fact references was correctly rejected; schema and reference instructions were clarified before retesting. Credentials remain ignored and absent from the phone bundle.

- OpenRouter live success: after including the schema in the prompt and disabling optional reasoning (which previously exhausted the response budget), fictional-bill validation and interpretation both returned HTTP 200 through the protected relay. Category bills, recipient Alex Example, payment USD 125.00, deadline 2026-11-15, and document date 2026-10-01 matched the source in both languages. The direct verification call reported 2403 input / 695 output tokens and cost 0. The output can still repeat an amount fact; comprehensive fixture and physical-device acceptance remain pending. Debug rebuilt and simulator app reinstalled. No slice completion or commit claimed.

- Early learner feedback: the user confirmed the simulator interpretation displays normally, but reported no finish button. Added a persistent bilingual Finish reading action on the result screen; confirmation explains that the unsaved letter is cleared before returning to capture. Keep reading cancels without losing the result. Photograph another letter remains available. Hide the obsolete photo-validation message after interpretation. Learner retry and physical-device acceptance remain pending.

- Finish-reading refinement verification: Debug simulator build and all eight existing iOS unit tests passed; updated app installed and opened on iPhone 17 Pro simulator. The new visible control still awaits learner retry.

- Capture-flow refinement requested by the learner: bring forward temporary multi-page capture into the current core flow so Photograph next page and Finish taking photos perform real actions. This does not add archive/account work early; persistence and archive organization remain in their approved slices. Retakes preserve other pages and finish submits the accepted originals together. The learner clarified that printed page numbers must not be checked: preserve capture order only; Finish is the user's declaration of completeness, not model inference.

- Multi-page refinement checks: ten iOS unit tests pass, including preservation/order across retake and retry and blocking completion while a captured photo is rejected. Seventeen relay/provider tests pass, including stale-token/byte checks, abandoned-retake handling, source-reference bounds, and neutral photo-quality prompts. A first live continuation image was incorrectly flagged due to the former Page 1 of 1 request label; removed that label from photo validation and separated photo-quality checks from letter interpretation. No printed-number validation is requested.

- Live two-photo verification succeeded after photo-quality-only prompt correction: both fictional images returned valid/HTTP 200, and combined interpretation returned HTTP 200. It correctly combined the first photo's USD 125.00 / 2026-11-15 payment with the second photo's SAMPLE-204 reference, with evidence pointing to both captured images. Printed PAGE 2 did not block acceptance. Updated simulator build is installed; learner retry and remaining slice-1 physical-device checks are pending.

- Phone-test setup: user connected the physical iPhone; Mac pairing succeeded. Generic iOS Debug build passes with signing disabled (compile evidence only, not installable signing). Ignored local relay/app settings now point to the Mac's private LAN address; token-protected relay is running and unauthenticated access returns401. Device reports Developer Mode disabled and no valid signing identity is available yet. Xcode opened; learner must enable Developer Mode and select their Apple signing team before signed install/launch. No phone acceptance claimed; avoid regenerating the Xcode project after learner sets signing without preserving it.

- Phone-test follow-up: Apple development identity and selected project team are now available. Generic signed build could not create a profile because the team has no registered device; retrying against the actual paired phone with automatic device registration. The phone still reports Developer Mode disabled, so learner was asked to complete the post-restart enable confirmation. LAN relay remains reachable and rejects unauthenticated access. Do not regenerate the Xcode project: learner signing edits must be preserved.

- Developer Mode is now verified enabled. Physical-device installation remains blocked by toolchain support: phone reports iOS27.0, installed Xcode26.5 build17F42 on macOS26.3.1. Official component update check returned no newer updates for17F42; DDI mount failed with PersonalizedBundleMissingVariantError (missing image variant for this phone). Apple lists Xcode27 for iOS27 SDK and requires macOS26.6 or later. No app installation or signed-build success claimed. Next prerequisite is user-managed macOS/Xcode update; preserve local signing/project edits and credentials, then retry provisioning/install. Reference: https://developer.apple.com/xcode/system-requirements

- Device installation now succeeds after update to macOS27.0.1 and Xcode27.0 (27A266a). Signed Debug build and provisioning succeeded using the learner-selected team; app installed on the connected iPhone18Pro. Launch was denied by iOS security (signature/entitlements/profile trust); local signature verification run, and next step is learner checking developer trust on the phone. Private LAN relay restarted and reachable (unauthenticated401). No successful phone launch or camera/AI acceptance claimed yet.

- Physical-test feedback: learner reported completing phone testing and requested quiet successful photo checks. Accepted photos now show a brief status without automatic spoken quality commentary; rejected/uncertain photos speak one concise reason and a retake instruction. Capture guidance and VoiceOver support remain. Exact physical acceptance coverage is not yet inferred from the brief feedback.
- Quiet-photo refinement: signed iOS Debug build passed and updated app installed on the connected phone. Success-path speech is omitted in code; retake reason is bounded to one short sentence followed by an explicit retake instruction. AI relay restarted with concise validation prompts. Learner retry of spoken behavior remains pending.

- October 2: learner requested a generic interpretation design within the existing medical/health-insurance scope after observing bare numbers and misleading date emphasis. Added contextual fact labels/explanations, required/optional/conditional action roles, distinct effective/service/date-period types, and collapsed source details. Validate fictional statement, EOB, test-result, and enrollment scenarios; no financial or government domain expansion. Existing five archive categories remain; classification review does not prevent an in-scope explanation.

- Generic interpretation verification: 21 Deno contract tests/typecheck and 11 iOS tests passed; signed device build succeeded and installed. Live fictional statement and lab-result cases passed structure and correctly avoided payment/treatment instructions. EOB replay retained optional record-keeping and separate amount roles. Enrollment remains an accuracy concern: first outputs violated optional-condition shape, later output omitted conditional actions despite retaining the deadline; no broad factual acceptance claimed. Alternative free Qwen model returned rate-limit errors, so no provider switch was made. Testing bounded reasoning before closing refinement. Real user letter images were not replayed to providers during these checks.
- Bounded-reasoning enrollment experiment returned provider_unavailable; production remains the original pinned free model with reasoning disabled. No paid fallback or model migration. Generic UI/contract refinement is implemented, but conditional-enrollment live accuracy remains unresolved and must not be marked accepted. Next work should improve/evaluate extraction reliability on these fictional regression cases before later slices.

- October 2 learner acceptance: user explicitly confirmed the current version is OK and approved it as the baseline. Early hands-on feedback is complete; preserve the current layout and behavior. Save an implementation checkpoint now without claiming the remaining accuracy/accessibility checks have passed or the whole product is ready.

### Remaining core verification

- [ ] Improve and re-evaluate conditional enrollment extraction on fictional fixtures; preserve optionality and effective-date meaning.
- [ ] Finish explicit physical capture/retake and English/Mandarin/VoiceOver acceptance evidence; a general test-completed message does not establish every individual check.
