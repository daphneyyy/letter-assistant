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
6. Select an extracted action, review conditions and dates, and confirm the calendar proposal.
7. Save or cancel in the system calendar editor; read the actual outcome.
8. Finish reading or start another letter, with a clear explanation that the current letter is not saved.

## Screens and Layout

One capture/interpretation flow, a calendar review sheet, and Apple's creation editor. No account screen or Chat/Archive/Calendar tabs. A Debug home-screen test entry offers fictional deadline, reminder and appointment examples without AI.

## Look and Feel

Keep the accepted simple layout: large Dynamic Type text, wrapping Chinese copy, at least 44-point controls, system colors, visible status text and VoiceOver labels. Successful photo checks stay quiet; failed/uncertain checks provide concise guidance.

## Page Capture and Validation

Use the native camera with its retake/use-photo controls. Preserve accepted pages and capture order when retaking another page. Check readability on-device, without AI/network calls. Almost no recognized text requires retake; uncertain blur/confidence offers Retake or Use anyway. Retaking clears prior acceptance. Do not check cropping, page edges or printed page numbering. Finish capture is the user's declaration of completeness. Preserve the current 10-page and per-image size limits, reporting them explicitly.

## Actionable Explanation

Display these sections in order:

1. What this letter says / 这封信主要说什么
2. What to pay attention to / 你需要留意什么
3. Actions and choices / 事项与选择
4. Relevant timing / 相关时间

Keep concise, contextual wording and expandable source details. Preserve relevant names, amounts, date roles and conditions consistently across languages. Distinguish required, optional and conditional actions. A coverage effective date or service date is not a deadline. An EOB amount is not automatically a payment request; medical results do not justify invented diagnosis/treatment advice. Missing instructions differ from an explicit statement that no action is necessary. An informational letter may have no actions or calendar entry.

Uncertain fields must be labeled for verification; unsupported domains receive an honest unsupported result. The existing five classification values may remain in the analysis contract but do not imply an archive or category browser.

## External Calendar Handoff

- Confirmed deadline: all-day event on the original date, including past/weekend dates without automatic rescheduling. Preserve any stated cutoff in notes.
- No deadline: user chooses a reminder date using Tomorrow / In 3 days / In one week / a custom date. Explicitly identify it as a reminder, not a deadline in the letter. No automatic urgency inference is required.
- Appointment: user verifies/enters the time and time zone. Current AI output supplies date-only facts. The initial 30-minute duration is an editable calendar convenience, not a fact from the letter.
- Uncertain action/date: show the uncertainty, require user verification and explicit date/time selection.
- Review title, source, condition, date and time zone before opening the system editor. Relative date choices become concrete dates; reconfirm if review crosses midnight.
- Alerts are configured in the system editor. All-day status alone does not guarantee an alert.
- Only a saved callback reports success. Canceled means unchanged letter; unknown/interrupted means check Calendar before retry. No automatic retry, event reading, link storage or synchronization.
- Later edits and removal occur in the phone calendar. Finishing a reading does not remove a saved calendar event.

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
- [ ] Save, cancel/Discard Changes, unavailable calendar and unknown/interrupted outcomes are verified honestly; inspect notes and alert controls on the phone.
- [ ] Large text, Chinese wrapping and basic VoiceOver remain usable.
- [ ] API credentials and local config are excluded from tracked files and publication history; only fictional fixtures are included.
- [ ] Learner completes the final hands-on review. No login, saved chat, archive or second-phone test is a hackathon requirement.

## Future Commercial Features

See `scope.md > Future Commercial Roadmap`: in-app calendar with phone synchronization, account/login, chatbox, and saved letter summaries/extracted information/question summaries/added-item summaries. Future storage and synchronization choices require their own product and technical design.
