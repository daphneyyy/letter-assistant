---
doc: prd
status: approved
---

# Letter Assistant — Hackathon Product Requirements

Approved October 2, 2026, through the learner's explicit scope revision. This document replaces the former login/archive/chat requirements for the hackathon.

## What We're Building

A no-login iPhone demo: photograph a medical or health-insurance letter, check photo readability, analyze its meaning and actions, and optionally add a reviewed item to the phone calendar. Distribute the source on GitHub so operators can clone it and use their own API key.

## The Core Journey

1. Open the app and select English or Chinese.
2. Use the native iPhone camera, accept or retake a page, and repeat for additional pages.
3. Local checks classify the page as readable, uncertain, or unreadable.
4. Finish capture to request AI interpretation of all accepted pages together.
5. Read the four sections and, when needed, expand facts and source excerpts.
6. Select an extracted action, review conditions, event date/time and notification alert, then tap Add to calendar.
7. Grant write-only Calendar permission if requested, then read the direct-save result. Not now exits without saving.
8. Finish reading or start another letter, with a clear explanation that the current letter is not saved.

## Screens and Layout

One capture/interpretation flow, a calendar review sheet with direct saving; no Apple creation editor. No account screen or Chat/Archive/Calendar tabs. An expandable Debug home-screen Demo tools / 演示工具 entry offers fictional deadline, reminder and appointment examples without AI. The home screen has a prominent capture button, bilingual language selection and a short three-step introduction, without the decorative envelope logo. Selected captured pages are visibly distinguished; original photos on the result screen are expandable.

## Look and Feel

Keep the accepted simple layout: large Dynamic Type text, wrapping Chinese copy, at least 44-point controls, adaptive system backgrounds with teal accents, visible status text and VoiceOver labels. Verify contrast and touch targets rather than treating the styling alone as accessibility acceptance. Successful photo checks stay quiet; failed/uncertain checks provide concise guidance.

## Page Capture and Validation

Use the native camera with its retake/use-photo controls. Preserve accepted pages and capture order when retaking another page. Check readability on-device, without AI/network calls. Almost no recognized text requires retake; uncertain blur/confidence offers Retake or Use anyway. Retaking clears prior acceptance. Do not check cropping, page edges or printed page numbering. Capture guidance should ask for readable text rather than requiring every page edge to be visible; the current home-screen edge wording remains a tracked correction. Finish capture is the user's declaration of completeness. Preserve the current 10-page and per-image size limits, reporting them explicitly.

## Actionable Explanation

Display these sections in order:

1. What this letter says / 这封信主要说什么
2. What to pay attention to / 你需要留意什么
3. Actions and choices / 事项与选择
4. Relevant timing / 相关时间

Keep concise, contextual wording and expandable source details. Preserve relevant names, amounts, date roles and conditions consistently across languages. Distinguish required, optional and conditional actions. A coverage effective date or service date is not a deadline. An EOB amount is not automatically a payment request; medical results do not justify invented diagnosis/treatment advice. Missing instructions differ from an explicit statement that no action is necessary. An informational letter may have no actions or calendar entry.

Uncertain fields must be labeled for verification; unsupported domains receive an honest unsupported result. The existing five classification values may remain in the analysis contract but do not imply an archive or category browser.

## External Calendar Handoff

- Confirmed deadline: prefill an editable all-day calendar date with the source deadline, including past/weekend dates without automatic rescheduling. All event types offer an editable time-zone picker defaulting to the phone zone. Changing the zone preserves the displayed day/clock; custom absolute alerts stay fixed. Keep the source deadline unchanged; when scheduling on a different calendar day, include that original deadline in saved notes. Preserve any stated cutoff in notes.
- No deadline: user chooses a reminder date using Tomorrow / In 3 days / In one week / a custom date. Explicitly identify it as a reminder, not a deadline in the letter. No automatic urgency inference is required.
- Appointment: user verifies/enters the time and time zone. The extraction now carries source-linked appointment date, local time (HH:mm) and any explicitly stated unambiguous time zone. A single confirmed date/time for the same action prefills the event; missing, conflicting or invalid times require manual entry with explicit placeholder wording. Missing time zones use the phone zone with a visible verification notice; an explicitly uncertain zone prevents time prefill. The review defaults to the phone zone for every event type; an explicitly zoned appointment is converted to that zone while preserving its instant. Repeated/nonexistent local times at DST transitions require manual review. The fictional appointment example has a known 10:00 AM time and prefills it, with no extra confirmation switch. For timed appointments, the AI supplies a separate suggested_duration_minutes setting (1–1,440 minutes), using explicit duration information when available or estimating from the event type. It is labeled as an AI estimate, never asserted as a source fact. Use it as the initial duration, with a clearly labeled 30-minute fallback for older/missing estimates. Offer 15/30/45/60/90/120/180/240-minute presets plus the estimate when different, and custom whole minutes from 1 to 1,440. Display the calculated end date/time, disable handoff for invalid input; valid edits need no additional confirmation switch. All-day deadlines/reminders have no duration suggestion or duration control.
- Uncertain action/date: show the uncertainty, require user verification and explicit date/time selection.
- Review title, source, condition, date, duration, time zone and alert before tapping Add. Relative date choices become concrete dates; if review crosses midnight, show the concrete date again and require another tap on Add. There are no date-verification or overall-confirmation switches. Complete prefilled events can proceed directly; missing dates/times must be supplied through the date picker (or reminder-date shortcuts). Tapping Add is the final save decision; there is no second review screen.
- Event date/time and notification time are separate. All-day status alone does not guarantee an alert. The app now offers alert selection during review; the selected alarm is saved with the event in the default writable calendar.
- All-day alert choices: None; on the day, 1 day before, 2 days before or 1 week before at 9 AM; custom date/time. Default: on the day at 9 AM in the review time zone.
- Appointment alert choices: None; at start; 5, 10, 15 or 30 minutes before; 1 or 2 hours before; 1 or 2 days before; 1 week before; custom date/time. Default: 15 minutes before. Day/week presets use calendar-day arithmetic in the selected time zone.
- Custom alerts use an exact date/time and stay fixed when the event date changes. Show that behavior explicitly. Past alert times produce a visible warning; the current implementation does not block them or silently reschedule them.
- Defaults are editable notification conveniences, not source facts or AI urgency recommendations. Existing saved calendar events are not updated by these app changes.
- Request only write-only Calendar access, using the iOS permission dialog on first use. Only a successful EventKit save reports success. Disable repeat taps and dismissal while saving, and prevent a second save within the same review. Permission denial offers Settings; no writable default calendar or save failure retains the form with an explanation. No automatic retry. An interrupted/uncertain result asks the user to check Calendar before retrying. No event reading, link storage or synchronization.
- Later edits and removal occur in the phone calendar. Finishing a reading does not remove a saved calendar event.

## Calendar Notes

Each action includes a short bilingual calendar_title (at most 100 characters per language), separate from its longer action description. Titles omit duplicate dates and generic Deadline/Reminder prefixes. Payment titles retain the classified source bill type, billing organization and confirmed linked payment amount even when AI calendar text or legacy descriptions are generic; other actions retain generated titles or description fallback. Source review deduplicates identical page/excerpt pairs without merging different-page evidence; extracted raw date sentences are not repeated under a misleading Letter date label.

Each action includes concise bilingual calendar_notes: an event brief containing the task and any source-supported location, contact, preparation or relevant amount. No greetings, assistant replies, review instructions, photo labels, raw-source dumps or AI-duration disclaimers. The app preserves conditions, optionality, explicit clock/cutoff qualifications and uncertainty as short factual annotations. A confirmed date-only deadline already represented by the event day does not append its entire raw payment sentence again; uncertain deadline text remains visible. Ordinary event date/time and selected duration remain in the event fields rather than duplicated notes. Missing legacy note fields fall back to the action description, never the review source text. Fictional examples have explicit short test notes.

Show the exact note in the review before Add; write that note unchanged to EventKit. Review/source instructions remain in the app only. Re-analyze after a relay update to obtain new AI notes; already saved events are not rewritten.

## Data and Open-Source Experience

No user account, email, cloud archive or app-owned conversation history. Photos/results are temporary in memory. The operator configures their own API key and compatible vision model on their Mac; photos are sent to that configured provider only when interpretation is requested. Local photo checks and calendar examples need no AI key. Never ship real keys or personal letters in the repository.

## Recovery Behavior

| Situation | Required behavior |
| --- | --- |
| Camera denied/canceled | Settings or cancel path; retain existing pages |
| Photo unreadable/uncertain | Retake, or explicit acceptance only for uncertain quality |
| Missing relay/API settings | Explain setup requirement; retain no-AI test access |
| Offline, quota, provider or invalid-output failure | Honest error and retry; preserve current pages |
| Unsupported or no-action letter | Explain result; do not invent an action |
| Calendar canceled/unavailable/unknown | Honest outcome; no success claim or automatic duplicate creation |
| Finish/restart | No archive claim; saved events remain managed by Calendar |

## Demonstration and Acceptance

- [ ] Clone/setup instructions work with operator-owned configuration and no account/email service.
- [ ] Physical iPhone captures a fictional page, handles an unreadable/uncertain photo and a retake, and preserves multi-page order.
- [ ] Real AI output works in both languages, including no-action/no-deadline cases and source-grounded conditional actions; known enrollment reliability issues must be recorded, not hidden.
- [ ] A deadline/reminder saves as an actual all-day event on the reviewed date; appointment time, duration and time zone are correct.
- [ ] Direct save, permission grant/denial, Not now, unavailable calendar and unknown/interrupted outcomes are verified honestly; inspect saved notes and alarms on the phone.
- [ ] Large text, Chinese wrapping, contrast, touch targets and basic VoiceOver remain usable on the current screens.
- [ ] Verify preset/custom/None alerts in newly saved phone events and observe notification delivery with Calendar notifications enabled; automated alarm construction does not prove delivery.
- [ ] Record permission-dialog comprehension and unresolved usability findings; do not claim target-user validation without observation.
- [ ] API credentials and local config are excluded from tracked files and publication history; only fictional fixtures are included.
- [ ] Learner completes the final hands-on review. No login, saved chat, archive or second-phone test is a hackathon requirement.

## Older-Adult Usability Review — Open Work

The prototype has accessibility foundations, but independent use by older adults has not been established. Automated large-text and calendar-flow checks are supporting evidence only.

Proposed next refinements, not implemented or accepted by this documentation update:

- Summarize the action, event date/time and notification time before detailed source/settings, retaining conditions and uncertainty.
- Show a few common alert choices first and place the full set under More options; preserve the requested flexibility and custom time.
- Explain direct saving and the permission dialog in plain language; verify English/Chinese device-language combinations.

Before claiming suitability for independent older-adult use, observe target users using fictional letters without step-by-step coaching. Record whether they can capture/retake, explain the action and any condition, distinguish the event date from notification time, save/cancel, and understand that the letter itself is not archived. Record assistance, errors and confusion, not merely task completion. This is separate from the learner's technical demo acceptance.

## Future Commercial Features

See `scope.md > Future Commercial Roadmap`: in-app calendar with phone synchronization, account/login, chatbox, user-facing letter classification, multilingual support beyond English/Chinese, and saved letter summaries/extracted information/question summaries/added-item summaries. Future storage and synchronization choices require their own product and technical design.
