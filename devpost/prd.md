---
doc: prd
status: approved
---

# Letter Assistant — Hackathon Product Requirements

This approved document defines the hackathon proof of concept. Login, archive and chat are future commercial features.

## What We're Building

A no-login iPhone demo: photograph or import a medical or health-insurance letter, bank/credit-card statement or an everyday bill/fee notice, check photo readability, analyze its meaning and actions, and optionally add a reviewed item to the phone calendar. Distribute the source on GitHub so operators can clone it and use their own API key.

## The Core Journey

1. Open the app in English or Simplified Chinese using the app-specific iPhone language setting or phone preference; the globe button opens Settings to change it.
2. Photograph a page with the native camera, choose an existing photo with PhotosPicker, or import a PDF with the system file picker; add further pages within the 10-page limit.
3. Local checks classify the page as readable, uncertain, or unreadable.
4. Tap Analyze document / 分析文档 to request AI interpretation of all accepted pages together.
5. Read the four sections and, when needed, expand facts and source excerpts.
6. Select an extracted action, review conditions, event date/time and notification alert, then tap Add to calendar.
7. Grant write-only Calendar permission if requested, then read the direct-save result. Not now exits without saving.
8. End the reading with the single fixed-bottom Finish reading button; confirm that the unsaved letter will be cleared and return to the home screen. Do not show a separate Photograph another letter button on the result page.

## Screens and Layout

One capture/interpretation flow and a calendar review sheet with direct saving; no Apple creation editor, account screen or Chat/Archive/Calendar tabs. Test/Debug builds have a default-collapsed Demo tools / 演示工具 section with Use test photo and fictional deadline, reminder and appointment examples. Prod/Release excludes these tools and fixtures.

A short welcome screen shows “One letter. Clear next steps.” and its explanatory subtitle once per app launch in the selected app language. It automatically continues after about two seconds, with a Continue button for immediate entry; with VoiceOver active, Continue controls dismissal. Returning from a letter or resuming from the background does not show it again. The welcome has no test-version footer.

The home screen has a globe button at the top right that opens the app's iPhone Settings page for English/Chinese selection. A mint card titled Start with your letter / 从您的信件开始 contains three actions: Take a New Photo / 拍摄新照片, Upload Existing Photo / 上传已有照片, and Upload Document (PDF) / 上传文档（PDF）. A shield note explains no signup, AI submission only when analysis is requested, and session-only app storage. A default-collapsed How to use / 如何使用 section contains the three steps. The decorative envelope logo is removed; the launch slogan/subtitle is confined to the welcome screen.

Use a warm off-white background in light mode, an adaptive dark background, strong headings, generous spacing and thin dividers, with deep-teal primary actions and mint highlights. Primary action buttons stack icons above labels at accessibility text sizes; actual readability and touch targets still need verification. Calendar review uses the same style with an in-page time-zone menu, compact date/time controls on separate rows, and a duration capsule that opens hour/minute wheels.

Swipe horizontally through captured pages or use the current/total page menu to jump to a page. Tapping a photo opens a full-screen viewer with page swiping, pinch zoom and double-tap zoom. Before interpretation, users can delete the current page after confirmation; preserve remaining pages and their order, returning to the start when the last page is deleted. Disable page changes/deletion while loading, checking or interpreting. Original photos on the result screen are expandable. Retain the AI-send/session privacy guidance and calendar-demo notice.

## Look and Feel

Keep the accepted simple layout: large Dynamic Type text, wrapping Chinese copy, at least 44-point controls, adaptive system backgrounds with teal accents, visible status text and VoiceOver labels. Verify contrast and touch targets rather than treating the styling alone as accessibility acceptance. Successful photo checks stay quiet; failed/uncertain checks provide concise guidance.

## Page Capture and Validation

Use the native camera with its retake/use-photo controls, PhotosPicker for existing photos, or the system file picker for PDFs only. PDF pages are rendered locally in order and checked before analysis. Reject locked/invalid PDFs, files over 30 MiB (shown as 30 MB in the interface), and documents exceeding the remaining 10-page capacity. Prepare all imported pages before adding any, preserve readable and unreadable pages for review, and block analysis until every page is accepted. PhotosPicker remains available for adding another photo. Imported photos use the same local readability checks and page limits. Selecting a next photo appends a page; replacing an unreadable page preserves the other pages. Canceling selection leaves the current letter intact; loading failure offers a retry without discarding accepted pages. The picker grants access only to selected items. Preserve accepted pages and capture order when retaking another page. Check readability on-device, without AI/network calls. Almost no recognized text requires retake; uncertain blur/confidence offers Retake or Use anyway. Retaking clears prior acceptance. Do not check cropping, page edges or printed page numbering. Capture guidance asks for clear, readable text one page at a time, without requiring every page edge to be visible. Analyze document is the user's declaration that all pages are ready. Enforce 10 pages, an 800-pixel minimum short edge and a 10 MiB limit per prepared image, reporting limit failures explicitly.

## Actionable Explanation

Explain bank checking/savings statements and credit-card statements. Distinguish account funds, opening/closing balances, deposits/withdrawals, credits, statement balances and minimum payments. Informational account statements need not offer any action. A credit-card payment task uses only the explicitly required minimum amount when stated, while showing the full balance separately; paying the minimum is not described as settling the balance. Statement dates and transaction dates are not payment deadlines. Source-stated autopay creates no duplicate manual-payment task. Keep full account/card identifiers out of summaries/calendar copy and explain documents without inventing payment/dispute steps or financial strategy recommendations.

Also interpret everyday electricity/gas/water, telephone/mobile/internet, membership/subscription and other household/service bills or fee/renewal notices. Display grounded bill type, billing organization, actual amount due and relevant date roles in the selected app language. Distinguish gross charges, prior balance, credits, payments already received and outstanding balance. Paid/zero-balance documents and scheduled automatic debits must not become manual-payment actions. Report autopay/renewal dates as source facts; only explicit payment or cancellation cutoffs become deadlines. Cancellation is conditional on the reader wanting to avoid renewal and on source-stated options. If an actual payment is requested without a due date, preserve that uncertainty and allow a user-selected reminder date. Preserve source-specific bill wording in calendar titles/notes, with organization and linked amount as fallback context. Medical/EOB behavior remains supported. Bank/checking/savings and credit-card statements are also supported. Investment/retirement reports and non-health insurance policy documents remain unsupported.

Generate explanations, action descriptions, conditions and calendar titles/notes only in the selected app language (English or Simplified Chinese). Source quotations keep their original language. The app-specific iPhone language preference can override the phone language. Previously generated bilingual results remain readable.

Display these sections in order:

1. What this letter says / 这封信主要说什么
2. What to pay attention to / 你需要留意什么
3. Actions and choices / 事项与选择
4. Relevant timing / 相关时间

Keep concise, contextual wording and expandable source details. Preserve relevant names, amounts, date roles and conditions consistently across languages. Distinguish required, optional and conditional actions. A coverage effective date or service date is not a deadline. An EOB amount is not automatically a payment request; medical results do not justify invented diagnosis/treatment advice. Missing instructions differ from an explicit statement that no action is necessary. An informational letter may have no actions or calendar entry.

Uncertain fields must be labeled for verification; unsupported domains receive an honest unsupported result. The existing five classification values may remain in the analysis contract but do not imply an archive or category browser.

## External Calendar Handoff

- Confirmed deadline: date-only cutoffs prefill an editable all-day date; explicit clock cutoffs prefill a timed deadline marker in the stated source zone. Preserve past/weekend dates without automatic rescheduling. All event types offer an editable time-zone menu on the same review page; timed deadlines use the source zone when available, while other cases default to the phone zone. Date and time use compact controls on separate labeled rows; neither control navigates to another page. Changing the zone preserves the displayed day/clock; custom absolute alerts stay fixed. Keep the source deadline unchanged; when scheduling on a different calendar day, include that original deadline in saved notes. Preserve any stated cutoff in notes.
- No deadline: prefill tomorrow as an editable personal reminder date; the user may keep it or choose Tomorrow / In 3 days / In one week / a custom date. Explicitly identify it as a reminder, not a deadline in the letter. No automatic urgency inference is required.
- Appointment: user verifies/enters the time and time zone. The extraction now carries source-linked appointment date, local time (HH:mm) and any explicitly stated unambiguous time zone. A single confirmed date/time for the same action prefills the event; missing, conflicting or invalid times require manual entry with explicit placeholder wording. Missing time zones use the phone zone with a visible verification notice; an explicitly uncertain zone prevents time prefill. Appointment review defaults to the phone zone; an explicitly zoned appointment is converted to that zone while preserving its instant. Repeated/nonexistent local times at DST transitions require manual review. The fictional appointment example has a known 10:00 AM time and prefills it, with no extra confirmation switch. For timed appointments, the AI supplies a separate suggested_duration_minutes setting (1–1,440 minutes), using explicit duration information when available or estimating from the event type. It is labeled as an AI estimate, never asserted as a source fact. Use it as the initial duration, with a clearly labeled 30-minute fallback for older/missing estimates. Show the current duration in a compact capsule beside Duration; tapping it opens an hour/minute wheel popover for any whole-minute duration from 1 to 1,440. Dismissing it retains the selection and hides the wheels. Display the calculated end date/time, disable handoff for invalid input; valid edits need no additional confirmation switch. All-day deadlines/reminders have no duration suggestion or duration control.
- Uncertain action/date: show a verification warning and source details. The warning does not itself block saving; a missing or invalid date/time still requires explicit entry. Keeping valid prefilled fields requires no separate verification switch.
- Review title, source, condition, date, duration, time zone and alert before tapping Add. Relative date choices become concrete dates; if review crosses midnight, show the concrete date again and require another tap on Add. There are no date-verification or overall-confirmation switches. Complete prefilled events can proceed directly; missing dates/times must be supplied through the date picker (or reminder-date shortcuts). Tapping Add is the final save decision; there is no second review screen.
- Event date/time and notification time are separate. All-day status alone does not guarantee an alert. The app now offers alert selection during review; the selected alarm is saved with the event in the default writable calendar.
- Deadline/reminder alert choices (including timed deadline markers): None; on the day, 1 day before, 2 days before or 1 week before at 9 AM; custom date/time. Defaults: deadlines use the day before at 9 AM; undated personal reminders use the chosen day at 9 AM, in the review time zone.
- Appointment alert choices: None; at start; 5, 10, 15 or 30 minutes before; 1 or 2 hours before; 1 or 2 days before; 1 week before; custom date/time. Default: 1 day before. Day/week presets use calendar-day arithmetic in the selected time zone.
- Custom alerts use an exact date/time and stay fixed when the event date changes. Show that behavior explicitly. Past alert times produce a visible warning; the current implementation does not block them or silently reschedule them.
- Defaults are editable notification conveniences, not source facts or AI urgency recommendations. Existing saved calendar events are not updated by these app changes.
- Request only write-only Calendar access, using the iOS permission dialog on first use. Only a successful EventKit save reports success. Disable repeat taps and dismissal while saving, and prevent a second save within the same review. Permission denial offers Settings; no writable default calendar or save failure retains the form with an explanation. No automatic retry. An interrupted/uncertain result asks the user to check Calendar before retrying. No event reading, link storage or synchronization.
- Later edits and removal occur in the phone calendar. Finishing a reading does not remove a saved calendar event.

The calendar-save confirmation button reads Back to result / 返回解读结果.

## Calendar Notes

For credit-card payment reminders, display the confirmed full statement balance in the title, keeping the source-required minimum separately labeled in notes. The full balance is not relabeled as the required minimum. Timed cutoff events instruct the reader to complete the task before the source cutoff; the marker is not a recommended task start.

Each action includes a short selected-language calendar_title (at most 100 characters per language), separate from its longer action description. Titles omit duplicate dates and generic Deadline/Reminder prefixes. Payment titles retain the classified source bill type, billing organization and confirmed linked payment amount even when AI calendar text or legacy descriptions are generic; other actions retain generated titles or description fallback. Source review deduplicates identical page/excerpt pairs without merging different-page evidence; extracted raw date sentences are not repeated under a misleading Letter date label.

Each action includes concise selected-language calendar_notes: an event brief containing the task and any source-supported location, contact, preparation or relevant amount. No greetings, assistant replies, review instructions, photo labels, raw-source dumps or AI-duration disclaimers. The app preserves conditions, optionality, explicit clock/cutoff qualifications and uncertainty as short factual annotations. A confirmed date-only deadline already represented by the event day does not append its entire raw payment sentence again; uncertain deadline text remains visible. Ordinary event date/time and selected duration remain in the event fields rather than duplicated notes. Missing legacy note fields fall back to the action description, never the review source text. Fictional examples have explicit short test notes.

Show the exact note in the review before Add; write that note unchanged to EventKit. Review/source instructions remain in the app only. Re-analyze after a relay update to obtain new AI notes; already saved events are not rewritten.

## Data and Open-Source Experience

No user account, email, cloud archive or app-owned conversation history. Photos/results are temporary in memory. The operator configures their own API key and compatible vision model on their Mac; photos are sent to that configured provider only when interpretation is requested. Local photo checks and calendar examples need no AI key. Never ship real keys or personal letters in the repository.

## Recovery Behavior

During interpretation, show the actual elapsed waiting seconds. After 20 seconds, explain that uploading photos and generating output in the selected app language can take time, especially for multiple pages; results appear automatically when ready. Do not claim a completion percentage or invent upload/generation stages.

| Situation | Required behavior |
| --- | --- |
| Camera denied/canceled | Settings or cancel path; retain existing pages |
| Photo unreadable/uncertain | Retake, or explicit acceptance only for uncertain quality |
| Missing relay/API settings | Explain setup requirement; retain no-AI demo access in Test/Debug builds |
| Offline, quota, provider or invalid-output failure | Honest error and retry; preserve current pages |
| Unsupported or no-action letter | Explain result; do not invent an action |
| Calendar canceled/unavailable/unknown | Honest outcome; no success claim or automatic duplicate creation |
| Finish/restart | No archive claim; saved events remain managed by Calendar |

## Demonstration and Acceptance

The learner has confirmed the core iPhone capture/retake → explanation → saved Calendar event hands-on check passed. The unchecked items below track broader acceptance, including detailed edge cases and final demo readiness; they do not imply that the core flow is untested. See `checklist.md > Current State` for the existing automated/setup evidence.

- [ ] Clone/setup instructions work with operator-owned configuration and no account/email service.
- [ ] Physical iPhone captures a fictional page, handles an unreadable/uncertain photo and a retake, and preserves multi-page order.
- [ ] Real AI output works in both languages, including no-action/no-deadline cases and source-grounded conditional actions; known enrollment reliability issues must be recorded, not hidden.
- [ ] A date-only deadline/reminder saves as an actual all-day event on the reviewed date; explicit clock cutoffs save as timed markers; appointment time, duration and time zone are correct.
- [ ] Direct save, permission grant/denial, Not now, unavailable calendar and unknown/interrupted outcomes are verified honestly; inspect saved notes and alarms on the phone.
- [ ] Large text, Chinese wrapping, contrast, touch targets and basic VoiceOver remain usable on the current screens.
- [ ] Verify preset/custom/None alerts in newly saved phone events and observe notification delivery with Calendar notifications enabled; automated alarm construction does not prove delivery.
- [ ] Record permission-dialog comprehension and unresolved usability findings; do not claim target-user validation without observation.
- [ ] API credentials and local config are excluded from tracked files and publication history; only fictional fixtures are included.
- [ ] Learner confirms final hackathon demo readiness after the remaining acceptance work. No login, saved chat, archive or second-phone test is a hackathon requirement.

## Older-Adult Usability Review — Open Work

The prototype has accessibility foundations, but independent use by older adults has not been established. Automated large-text and calendar-flow checks are supporting evidence only.

Proposed next refinements, not implemented or accepted by this documentation update:

- Summarize the action, event date/time and notification time before detailed source/settings, retaining conditions and uncertainty.
- Show a few common alert choices first and place the full set under More options; preserve the requested flexibility and custom time.
- Explain direct saving and the permission dialog in plain language; verify English/Chinese device-language combinations.

Before claiming suitability for independent older-adult use, observe target users using fictional letters without step-by-step coaching. Record whether they can capture/retake, explain the action and any condition, distinguish the event date from notification time, save/cancel, and understand that the letter itself is not archived. Record assistance, errors and confusion, not merely task completion. This is separate from the learner's technical demo acceptance.

## Future Commercial Features

See `scope.md > Future Commercial Roadmap`: in-app calendar with phone synchronization, account/login, chatbox, user-facing letter classification, multilingual support beyond English/Chinese, and saved letter summaries/extracted information/question summaries/added-item summaries. Future storage and synchronization choices require their own product and technical design.
