---
doc: prd
status: approved
---

# Letter Assistant — Product Requirements

Working name: **Letter Assistant**.

Help middle-aged and older immigrants with limited English understand English medical and insurance letters, learn what to do next in English or Mandarin Chinese, organize letters by recipient, and review and confirm letter-generated events for creation in their iPhone's built-in calendar.

Source: `scope.md > Who It's For` and `The Unique Kernel`. The user explicitly approved this product requirements document. Technical implementation decisions belong to `4-spec`. The feature sections and recovery requirements incorporate the latest calendar, account, archive, and chat decisions. The product questions raised during review are resolved; the document is approved for technical planning.

## Scope Alignment

The core outcome remains understanding a letter and knowing what to do next. The following interview decisions revise the original scope:

| Area | Current requirement |
| --- | --- |
| Action management | Review and confirm letter-generated events, then create them in the iPhone calendar. Later changes and alerts are managed in the system calendar. |
| Archive | Retain original photos and summaries, organized by recipient and five visible categories; allow corrections. |
| Accounts | Add verified email plus password login, recovery through the same verified channel, and same-account access across phones. |
| Letter detail | Show a concise summary by default and provide access to a persistent letter-specific conversation whose full history syncs across phones. |
| Language | Choose a language after registration; allow changes in Settings, including existing summaries. |

These additions change the original 2–4-hour proof-of-concept boundary. No confirmed feature is silently removed here, but this expanded scope has not been validated against that time target. `scope.md` has been aligned with these approved decisions for implementation planning.

## Terms Used in This Document

| Term | Meaning |
| --- | --- |
| Letter | One document captured across one or more pages. |
| Recipient | The person named as the recipient in the letter, not necessarily the account owner. Filing under different names does not create different accounts. |
| Action item | Something the letter asks the user to do. It appears in a summary, without an in-app completion tracker. |
| Due date | A deadline explicitly stated in the letter and associated with an action. |
| Reminder date | A date selected or confirmed by the user to remember to handle an action; it is not evidence of a deadline. |
| Notification time | When the external calendar alerts the user. An all-day event alone does not define this time. |

## The Core Journey

1. Register with a verified email address and a password. After first registration, choose English or Chinese. This preference can later be changed in Settings.
2. Enter the AI chat home screen. Start photographing a letter using the capture button at the bottom. Bottom tabs switch between Chat and Archive.
3. Photograph the English medical or insurance letter one page at a time. The app checks each photo for clarity and whether part of the page is missing.
4. If a photo is invalid, spoken guidance explains the problem and the only page action is **Retake this page**. If valid, show **Next page** and **Done**. Selecting Done begins interpretation of the complete letter.
5. In chat, explain in large text: **What this letter is → What you need to do → What the deadline is**. Emphasize the next action.
6. Tap **Ask** to ask a spoken follow-up question and receive an answer grounded in the letter.
7. Archive the letter and its original photos, whether or not it contains an action. If action is required, the user may confirm an item to add to the phone's built-in calendar.
8. Manage later event changes and alerts in the system calendar. Browse Recipient → Category → letters sorted by date. Open a letter detail page for its concise summary, original photos, and action items, or resume its full conversation. The archive and full letter-specific chat history are available on another phone after signing into the same account.

Source: `scope.md > The Core Loop` and `What "Working" Looks Like`, refined by the interview.

## Screens and Layout

- **Registration, login, and initial language selection:** Verified email address plus password. Recover a forgotten password through the same verified channel. Choose English or Chinese after first registration.
- **Settings:** Change language. The location of the Settings entry has not been specified.
- **Chat home:** An AI chatbot is the main surface, with a capture button at the bottom.
- **Page capture:** Show the current page's validation result and available actions.
- **Letter explanation in chat:** Present the letter type, actions, deadlines, relevant amounts, and follow-up answers directly in chat.
- **Letter detail:** A separate page containing the letter summary, relevant points discussed in chat, action items, and access to original photos. Show the concise summary by default and provide an action to resume this letter's full conversation. Action items can be reviewed for calendar creation; later event changes are managed in the system calendar without changing original letter facts.
- **Archive tab:** Switch from Chat using bottom tabs. Browse Recipient → Category → letters sorted by date. Ambiguous classifications are accessible in a temporary Needs review state under the recipient; this is a review state, not a sixth category.
- **System calendar:** Review and confirm a letter-generated event for creation. After saving, manage it in the iPhone calendar. V1 has no Calendar tab or ongoing event connection.

## Look and Feel

Minimalist, with large text and plain language. Keep visible categories few so older users do not have to navigate dozens of classifications. Specific colors and fonts have not been selected.

Source: `scope.md > Inspiration & Identity` and the interview.

## Features and Behavior

### Account and Cross-Phone Archive Access

Users register, choose a language, and access their own archive. Signing into the same account on another phone provides access to previously archived letters, including original photos, analysis, detail summaries, full letter-specific chat history, and saved corrections to recipients and categories. This does not imply sharing between different accounts.

Users register with a verified email address plus a password and use that channel and password to log in. Password recovery uses the same verified channel. Phone/email linking and account merging are out of scope for V1.

Acceptance criteria:

- [ ] Registration requires verification of the email address; the user can then log in with that identifier and a password.
- [ ] A user can recover a forgotten password through the same verified channel and regain access to the existing account and archive.
- [ ] V1 offers neither phone/email linking nor account merging.
- [ ] A letter archived on one phone can be found and opened, including its photos, summary, and full letter-specific conversation, after signing into the same account on another phone.
- [ ] Saved recipient and category corrections remain consistent across phones.
- [ ] One account cannot access another account's archive.

Source: New requirements confirmed during the product interview.

### Page Capture and Validation

Check each photo for clarity and whether the photographed page is fully visible. Invalid photos require a retake of the current page, with spoken guidance. A valid photo allows the user to continue or finish capturing the letter. Photo validation checks captured pages; it does not prove that the user has photographed every page of the original letter. Done is the user's declaration that capture is complete.

Source: `scope.md > The Core Loop`.

Acceptance criteria:

- [ ] A blurry photo or a photo missing part of the page triggers a retake prompt and shows only **Retake this page** as the page action.
- [ ] A valid photo shows **Next page** and **Done**.
- [ ] Retaking a page replaces that page's rejected photo, preserves previously accepted pages, and does not create an extra page in the letter.
- [ ] Spoken prompts guide the user through retakes and subsequent pages.
- [ ] After capture is complete, all pages are interpreted as one letter.

### Actionable Explanation and Voice Questions

Explain the letter type, required action, and deadline in that order. Emphasize next steps and include relevant amounts and consequences explicitly stated in the letter. Support English and Mandarin Chinese, with written Chinese for the latter. The Ask button starts a spoken question; answers are grounded in the current letter.

Keep extracted letter facts, user-provided information, and AI suggestions distinct. A letter's issue date, service date, or appointment date must not be relabeled as an action deadline. “Not specified” means the information is absent from a readable letter; “Needs verification” means it could not be confirmed. Neither should be rewritten as “No action is needed.”

Source: `scope.md > The Unique Kernel` and `The POC Boundary`.

Acceptance criteria:

- [ ] Results appear in the order **What this is → What to do → Deadline**.
- [ ] When no action is specified, show **The letter does not specify what you need to do** in the selected language.
- [ ] When an action has no stated deadline, show **The letter does not specify a deadline**.
- [ ] Uncertain amounts, dates, or actions are marked as needing verification; information and consequences are not invented.
- [ ] The user can receive an English or Chinese explanation and ask a spoken follow-up question grounded in the letter.
- [ ] Language selection appears after first registration and can be changed in Settings.
- [ ] Previously saved letter summaries display in the newly selected language. Original letter photos remain unchanged.
- [ ] Changing the summary language preserves names, amounts, dates, and the distinction between letter facts and suggestions.
- [ ] For a question the letter cannot answer, the response states that the information cannot be confirmed from the letter rather than inventing an answer.

### Letter Detail Summary

Each letter has its own persistent conversation, beginning with the initial interpretation. The separate detail page shows a concise summary of the letter, relevant discussion, and action items by default. Users resume the letter-specific conversation from this page. The full conversation history syncs across phones for the same account; a summary does not replace or discard it.

Source: Interview refinement of `scope.md > The Core Loop` and the new archive experience.

Acceptance criteria:

- [ ] Opening an archived letter shows its concise summary, relevant discussion points, and action items by default.
- [ ] The user can resume that letter's existing conversation from its detail page and see previous messages.
- [ ] Full letter-specific chat history is available on another phone after signing into the same account.
- [ ] Resuming one letter never mixes its conversation with another letter's history.
- [ ] Relevant points established in later chat are reflected in that letter's detail summary without mixing in other letters.
- [ ] The summary distinguishes deadlines explicitly stated in the letter from user-selected or AI-suggested reminder dates. Suggestions are not rewritten as requirements from the letter.
- [ ] User-provided information from chat remains distinguishable from facts extracted from the letter when summarized.
- [ ] Original photos are accessible from the detail page.
- [ ] The action summary does not introduce in-app completion tracking or reminder popups.

### Recipient and Letter Archive

Archive every interpreted letter, including letters with no action items. Retain both original photos and interpretation results for comparison. File letters under the recipient name printed on the letter. If the recipient cannot be confirmed, use **Unknown person**. This is a recipient fallback, not a category.

The first version handles medical and insurance letters only. Show five categories: **Bills, Insurance explanations, Appointments, Test results, and Medications**. AI may classify more finely internally without exposing many additional categories. Recipient, organization, and date help organize letters.

Use the actual recipient name, not an assumed family role. Browse Recipient → Category → letters sorted by date, with organization and date shown as metadata rather than mandatory folder levels. Bills includes medical bills.

Each letter has one primary visible category among the five existing categories. Ambiguous classifications enter a temporary **Needs review** state until the user confirms or corrects the category. Needs review is not a sixth category: pending letters remain accessible under their recipient and are not silently forced into a final category. After confirmation, the letter appears under its single primary category.

Source: Interview addition extending `scope.md > The Core Loop`.

Acceptance criteria:

- [ ] Letters without action items remain available in the archive.
- [ ] Reopening a letter provides its interpretation and corresponding original photos, keeping all pages associated with that letter.
- [ ] Letters can be found by recipient name; unidentified recipients appear under Unknown person.
- [ ] Visible categories remain limited to the five listed above; each classified letter has exactly one primary category.
- [ ] An ambiguous classification is marked Needs review and remains accessible until the user confirms or corrects it. Confirmation clears that state and files the letter under its selected category.
- [ ] Archive navigation follows Recipient → Category → letters sorted by date.
- [ ] The user can change a letter's category. After saving, it appears in the new category with its photos and interpretation still attached.
- [ ] The user can correct a letter's recipient name, including moving a letter out of Unknown person. Photos and interpretation follow the letter without modifying the original document.

### External Calendar Handoff

V1 only creates user-confirmed letter-generated events in the iPhone's built-in calendar. Later changes are managed in the system calendar. No in-app Calendar tab, bidirectional editing, cross-device calendar synchronization, event reconciliation, or calendar conflict handling is included. A separate Google Calendar integration is deferred.

The app presents source, title, due date where stated, reminder date, notification settings, and notes for review. These are product information requirements, not a claim that a calendar has separate native fields for all of them. The chosen calendar workflow must preserve their meaning. The system calendar stores created events and delivers notifications; this app does not track task completion or assume the calendar provides a completion checkbox.

Add an item only after the user chooses and confirms it; do not automatically add every action. Opening a calendar creation flow is not by itself proof that an item was saved. The final user-facing result must reflect what can actually be confirmed by the selected calendar workflow.

**Calendar date rules:**

| Source information | Calendar behavior after user confirmation |
| --- | --- |
| Explicit deadline | Create an event on the stated deadline date, with user-configurable advance notifications. |
| Explicit appointment | Use the stated appointment date and time. Do not convert it into a deadline or an arbitrary all-day reminder. |
| Action without a deadline or a stated appointment time | Create an all-day event on the user-confirmed reminder date. Explain that the letter did not state a deadline. |
| Past date | Show the original date as passed. Never silently move it to today or another date. |

Calendar alerts are reviewed in the system creation editor; later changes are made in the system calendar. The app does not schedule or send its own notifications. The user can configure advance alerts without changing the underlying deadline or appointment date. Missing or uncertain date/time information remains marked for verification rather than filled with invented values.

**Keep due dates and reminder dates distinct:**

- Populate a due date only when the letter explicitly states it and it can be confirmed. Otherwise show **The letter does not specify a deadline**. Never substitute a suggested reminder date for a missing deadline.
- For an action without a deadline, create an all-day event on the reminder date selected or confirmed by the user. A stated appointment date and time takes precedence over this fallback.
- AI may suggest a reminder date, clearly labeled as a suggestion. It is a product reminder suggestion, not an official deadline or a medical urgency assessment.
- The interface says **This letter does not specify a deadline. Would you like a reminder to handle it?** and offers **Tomorrow**, **In 3 days**, **In one week**, and **Choose a date**. The user may adjust the suggestion or decline to add an item.
- Example calendar title: **Handle: Blue Shield request for additional information**.
- Example note: **The original letter does not specify a deadline. This date is the reminder date you selected.** Retain source information as well.

The following user-defined ranges guide suggestions; they are not deadlines from the letter:

| Letter content | Suggested reminder range |
| --- | --- |
| Payment requested without a date | In 1–3 days |
| Call or submit information | In 2–3 days |
| Schedule a medical appointment | In 3–7 days |
| Update insurance or personal information | In 3 days |
| Routine, non-urgent administrative matter | In 7 days |
| Letter explicitly says “immediately,” “as soon as possible,” or “urgent” | Today or tomorrow |
| Urgency cannot be determined | Ask the user to choose; do not automatically suggest a date |

Select a specific suggestion by considering urgency evidenced by the letter, risks of inaction stated in the letter, preparation time, and whether the user needs to contact an organization. Favor earlier reminders for higher-risk matters or those involving payment, insurance eligibility, or important documents. Allow preparation time for documents or complex forms. When calling a hospital, insurer, or another organization is required, avoid weekends where practical; a weekday is not a guarantee that the organization is open. Do not invent consequences or treat the resulting suggestion as an official deadline.

Source: The learner explicitly simplified V1 during build-plan review to confirmed event creation only; see `scope.md > The Core Loop`. This supersedes the earlier in-app calendar proposal.

Acceptance criteria:

- [ ] The user can confirm an action for the external calendar and review its source, title, dates, reminder settings, and notes.
- [ ] Due dates and reminder dates are shown separately. AI suggestions are labeled and require user selection or confirmation.
- [ ] An action with no deadline remains labeled as having no stated deadline. Unless it has a stated appointment date and time, confirmation creates an all-day event on the reminder date, with a note explaining that date's meaning.
- [ ] An explicit deadline creates a user-confirmed event on the stated deadline date, with advance alerts configurable in the system creation editor.
- [ ] An explicit appointment uses the stated appointment date and time.
- [ ] A past date is labeled as passed and remains unchanged unless the user explicitly chooses a separate action; it is never silently rescheduled.
- [ ] Missing or uncertain dates/times are marked for verification rather than invented.
- [ ] Alert settings belong to the created system-calendar event; no independent app reminder system is introduced.
- [ ] Suggestions consider urgency, stated risks, preparation time, and contact requirements. Organization-contact suggestions avoid weekends where practical.
- [ ] No calendar item is created without confirmation.
- [ ] No separate in-app completion state or reminder popup is introduced.
- [ ] Later event edits are managed in the system calendar; the app neither reads them back nor promises synchronization.
- [ ] Save, cancel, unavailable, and unknown outcomes are reported honestly. An unknown outcome directs the user to check the system calendar; no automatic retry or event reconciliation is added.

## States and Boundaries

- **Invalid photo:** Give spoken retake guidance and remain in the current page's capture flow.
- **No explicit action:** Say the letter does not specify what to do and still archive it.
- **No explicit deadline:** Say no deadline is specified. Offer clearly labeled reminder suggestions or date selection; create an all-day calendar event only after confirmation.
- **Unknown recipient:** File under Unknown person until corrected.
- **Uncertain information:** Mark it as needing verification.
- **Needs review:** Keep an ambiguously classified letter accessible until its primary category is confirmed or corrected.
- **Past date:** Label the original date as passed without silently rescheduling it.
- **Reopening or changing phones:** Saved photos, interpretation, and full letter-specific conversations remain accessible after signing into the same account.
- **Incomplete operations:** Show a simple, relevant recovery action as specified below.

## Recovery Behavior

Incomplete states use simple recovery actions. The following requirements implement that confirmed direction without adding a separate reminder system.

| Situation | Required behavior |
| --- | --- |
| Empty archive | Show a short explanation and a button to photograph the first letter. |
| Photo check or interpretation in progress | Show a clear processing state and prevent a second submission of the same operation. |
| Interpretation or save failure | Explain the failure, retain captured pages for retry in the current session, and distinguish “interpreted” from “saved to your archive.” Do not claim cross-phone availability until saving succeeds. |
| Camera or microphone unavailable | Explain which capability is unavailable and how to retry or return. Do not trap the user in a capture or voice screen. |
| Voice input failure | Keep the current letter and existing conversation; allow another attempt without restarting the letter workflow. |
| Calendar canceled or unavailable | Preserve the letter and action summary. Do not report a saved calendar event; allow the user to try again. |
| Calendar opened without save confirmation | Say the calendar was opened and ask the user to check it, rather than asserting that an event was added. |
| All-day reminder notification | Let the user review or change the alert in the phone calendar's creation flow. Do not promise a notification merely because the event is all-day. |
| Unsupported letter domain | Explain that the first version supports medical and insurance letters; do not force it into one of those categories. |

Acceptance criteria:

- [ ] An empty archive offers a clear way to photograph the first letter.
- [ ] Processing is visible and cannot accidentally submit the same operation twice.
- [ ] Interpretation or save failure offers retry without discarding captured pages in the current session or claiming an unsuccessful save succeeded.
- [ ] Voice failure allows retry while preserving the current letter and conversation.
- [ ] Calendar cancellation returns the user to the letter without claiming an event was saved; calendar failure offers a retry.
- [ ] When the app cannot verify calendar saving, it reports only the handoff and directs the user to check the calendar.
- [ ] All alert settings belong to the created system-calendar event; recovery never creates independent app reminders.

## Demonstration and Acceptance

Use these scenarios to verify the confirmed behavior, including the recovery paths. The feature acceptance criteria remain authoritative.

1. **Capture and correction:** Photograph a multi-page letter, submit one cropped or blurry page, retake it, and complete capture. Verify that the accepted pages form one letter without a duplicate retake page.
2. **Stated deadline:** Use a letter with an explicit action, amount, and deadline. Verify that chat and details preserve those facts, and that the confirmed calendar event uses the stated deadline date with configurable advance alerts.
3. **Missing deadline:** Use an actionable letter without a deadline. Verify the missing-deadline label, a clearly identified reminder suggestion or user selection, explicit confirmation, and an all-day calendar item with the explanatory note.
4. **No action and archive correction:** Use a letter with no stated action. Verify that it is still archived, that its original photos can be opened, and that recipient and category corrections are retained.
5. **Follow-up and language:** Ask a letter-specific voice question and inspect the detail summary. Switch language and verify that the existing summary changes language without changing factual content or the original photos.
6. **Another phone and account separation (once at final acceptance):** Open a saved letter on another phone using the same account. Resume its full conversation from the detail page and verify previous messages. Verify that a different account cannot access it.
7. **Appointment and past date:** Confirm an appointment event uses the stated date and time. Open a letter with a past date and verify that it is labeled as passed and never silently moved.
8. **Ambiguous archive category:** Verify that an ambiguous letter enters Needs review, can be confirmed or corrected into one category, and is accessible through Recipient → Category → date-sorted letters.
9. **Account recovery:** Register through a verified email address, then recover the password through that same channel and reopen the existing archive.
10. **Incomplete operations:** Exercise an empty archive, processing, interpretation failure, voice failure, calendar cancellation, and calendar failure. Verify the recovery actions and ensure no unconfirmed success or independent reminder is reported.

## Product Decisions

- Minimalist styling, large text, and a small set of visible categories.
- AI chat home with a bottom capture button and bottom tabs for Chat and Archive.
- Only valid photos enable Done; invalid photos require Retake this page.
- Explain what the letter is, what to do, and the deadline, in that order.
- File by the letter's recipient name, using Unknown person when necessary.
- Limit the first version to medical and insurance letters.
- Review and confirm letter-generated events, then create them in the system calendar; all later changes and alerts are managed there.
- Extract deadlines only from the letter. AI may suggest reminder dates, confirmed by the user; actions without deadlines become all-day reminder events.
- Archive letters even when no action is required, preserving photos and interpretation.
- Allow corrections to recipient names and categories.
- Maintain one persistent conversation per letter, sync its full history across phones, and resume it from the detail page, which shows a concise summary by default.
- Use a verified email address plus password, with recovery through the same channel. No phone/email linking or account merging in V1.
- Use one primary category per letter, a temporary Needs review state for ambiguity, and Recipient → Category → date-sorted letters for browsing.
- Preserve explicit deadlines and appointment times in calendar events; label past dates as passed without silent rescheduling.
- Choose language after initial registration and change it in Settings; existing summaries follow the new language.

## What We're Building

Verified email registration, password login and same-channel recovery; cross-phone access to the same account's archive and full letter-specific conversations; language selection and settings; a minimalist chat home; bottom tabs; guided page capture and validation; English and Chinese explanations and voice questions; recipient-based archiving with five categories; editable recipient and category assignments, including temporary Needs review classification; letter details with original photos, discussion summaries, and action items; and user-reviewed, confirmed creation of letter-generated events in the iPhone calendar.

The expanded scope and original time target are described in **Scope Alignment**. Technical planning must assess effort and discuss any necessary tradeoffs with the user. The reviewed calendar, account, archive, chat, and recovery decisions are included in this version.

## Deferred From the POC

- Government, banking, transportation, and other letter domains: the user agreed to focus first on medical and insurance letters.
- A separate Google Calendar integration: prioritize the phone's built-in calendar.

## Possible Later Enhancements

Expand interpretation and classification to other letter domains after validating the medical and insurance workflow.

## Non-Goals

- Word-for-word translation as the primary output. Source: `scope.md > Explicitly Cut`.
- An in-app Calendar tab, bidirectional event editing, cross-device calendar synchronization, event reconciliation, or calendar conflict handling.
- A task-completion tracker, reminder popup, or independent phone push notifications.
- Phone-number authentication for signup, verification, login, or recovery.
- Phone/email linking and account merging in V1.
- Invented consequences or a fixed assumption that every insurance explanation means no payment is required.
- Cross-account family sharing is not implied by same-account access on another phone.

## Open Questions

The five product questions from review are resolved: calendar date handling, verified account access and recovery, archive ambiguity and browsing, persistent chat continuity, and incomplete-state recovery. No blocking product question remains from that review.

The learner selected iPhone and email-only account verification/recovery during technical planning. The revised spec defines creation-only system calendar handoff, email delivery configuration, date sorting with an explicitly labeled upload-date fallback, system colors/fonts, and Settings placement. The final product name remains open; Letter Assistant is the working name.

Letter Assistant remains a working name. This Markdown document is the canonical approved PRD. The user explicitly approved it on September 30, 2026. `3-prd` is complete; `4-spec` is complete; the learner approved `spec.md`, and `5-build` is next.

## Agreed Changes During Technical Planning

The learner selected iPhone as the first supported platform and agreed to a native Swift + SwiftUI app. Cloud services and a small testing budget are acceptable. The learner agreed to Supabase for email authentication, database, and private photo storage. The learner agreed to call OpenAI through the backend for letter-image interpretation and letter-grounded questions, including sending letter photos to OpenAI for processing. API credentials stay on the backend. The approved spec defines the initial model candidate and Resend email delivery setup; account access, domain verification, and actual costs still require build-time checks. The learner explicitly narrowed V1 to email registration, email verification, password login, and password recovery by email. Phone/SMS registration is deferred. Same-account access across iPhones remains required. These amendments preserve the approved status of this document; the learner subsequently approved the full technical specification on September 30, 2026, including Resend email delivery and the documented implementation defaults and limits. See `spec.md` for the approved blueprint and outstanding build prerequisites.

## V1 Simplification During Build Planning

The learner explicitly revised V1: email-only signup, verification, email/password login, and email password recovery; phone-number authentication is deferred. Calendar support is limited to reviewing, confirming, and creating letter-generated events in the iPhone calendar, with later changes managed there. The prior in-app calendar proposal is superseded, including bidirectional editing, cross-device calendar synchronization, event reconciliation, and calendar conflict handling.

The first build milestone proves capture of one fictional letter → photo validation → real AI interpretation before authentication or archive persistence. Accessibility starts in that milestone: large Dynamic Type, readable Chinese text, large tap targets, and basic VoiceOver support. Needs review is a classification state, not a sixth category; Unknown person is a recipient fallback, not a category. Cross-device archive and conversation behavior is verified once at final acceptance, not as a physical-device prerequisite for each slice. The final product retains email accounts and persistent archives/conversations. The checklist remains draft pending review of the revised build order.


Provider clarification (October 1, 2026): the learner uses an OpenRouter free API key. The build now routes AI image requests through OpenRouter to a pinned free vision model, with no paid fallback. This supersedes the earlier direct-OpenAI provider choice while preserving the product scope, backend-only credentials, and build order. Only fictional letters are used during development.


### Generic medical and health-insurance interpretation

October 2 learner-approved refinement: retain medical and health-insurance scope and the five archive categories, but do not force every letter into a payment/deadline template. Explain its purpose, explicit requests or choices (required, optional, or conditional), and relevant timing. Preserve any conditions and explicitly stated consequences; never infer applicability to the user. Informational letters may have no actions. Distinguish missing instructions from an explicit statement that no action is required. EOB figures are not automatically payment requests; medical results must not become inferred diagnoses or treatment advice. Enrollment can remain Needs review if none of the existing archive categories fits; this must not suppress a useful in-scope explanation. Retirement/banking material remains out of scope.

Each selected fact has bilingual label and explanation giving context to its canonical value; amounts identify their role rather than implying money owed. Dates distinguish deadline, effective date, service date, document date, appointment, and periods. Only an actual deadline can be linked as an action deadline. Conditional actions carry a bilingual condition and source evidence. The UI presents purpose / actions and choices / relevant timing, with source details initially collapsed. Display only relevant facts, not every number in the document. These changes refine interpretation, not authentication, archive, conversation, or calendar scope.
