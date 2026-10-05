---
doc: scope
status: approved
---

# Letter Assistant — Hackathon Scope

Approved revision: October 2, 2026. The learner explicitly narrowed the hackathon to capture → photo checks → analysis → user-confirmed iPhone calendar creation. This replaces the previous account/archive/chat scope; those features are future commercial work, not unfinished hackathon requirements.

October 4 approved expansion: the learner requested everyday billing support after naming electricity, telephone and membership fees. The expanded document range retains the same capture → analysis → reviewed calendar flow. Bank/checking/savings and credit-card statements are also supported after the October 4 banking follow-up. Investment/retirement reports and non-health insurance policy documents remain outside the supported range. No bill payment, account connection, automatic cancellation or recurring-calendar feature is added.

October 4 banking follow-up: the learner supplied a bank statement and requested support. Explain balances and transactions as source facts; only explicit payment instructions or conditional reporting requests create actions. Do not turn account funds into amounts due or add financial strategy advice.

## The Unique Kernel

Help middle-aged and older immigrants with limited English understand a medical or health-insurance letter, bank/credit-card statement or an everyday bill/fee notice: what it says, what to pay attention to, what actions or choices it contains, and when. Turn an applicable action into an event the user reviews and saves in the phone calendar.

## Who It's For

People who struggle to read English medical and health-insurance letters, bank/credit-card statements or everyday bills. The interface and explanations support English and Simplified Chinese, with large readable text and spoken capture guidance. Older-adult usability is a design goal, not a validated outcome: current automated checks do not establish independent use by the target audience. Technical clone/setup is performed by an operator; the current demo is not a self-installable consumer product.

## The Core Loop

1. Open the app and choose English or Chinese. No registration or login.
2. Photograph one or more pages using the iPhone camera.
3. Check readability locally; retake unreadable images, or explicitly accept uncertain quality.
4. Finish capture to analyze the ordered pages using the operator's own AI API key.
5. Read the explanation and source-backed facts, actions and relevant dates.
6. Review an action and its calendar date, then tap Add to save directly to the default iPhone calendar (write-only permission), or dismiss without adding.

## The POC Boundary

- Native iPhone app, local photo checks, temporary ordered multi-page capture and per-page retakes.
- AI interpretation of medical/health-insurance letters, bank/credit-card statements and everyday bills/fee or renewal notices, bilingual output and visible uncertainty. Everyday billing includes electricity/gas/water, telephone/internet, memberships/subscriptions and other household/service charges. Paid balances and scheduled automatic debits do not imply a manual-payment task; renewal dates do not imply a cancellation deadline.
- Creation-only iPhone calendar handoff: deadlines, user-selected reminder dates, and user-verified appointments. The review includes user-controlled notification alerts with presets, None, and a custom date/time, saved directly after tapping Add; no second system review. These settings do not infer urgency from the letter.
- No-AI fictional calendar examples for testing, clearly labeled as tests.
- Open-source, clone-and-run distribution on GitHub; each operator supplies their own compatible API key and model configuration.
- Current run mode: Mac-hosted local relay plus an iPhone Debug build installed with Xcode. No hosted shared service is promised.
- Photos and analysis stay in the active session; finishing/restarting does not provide an archive. Saved calendar events remain in the phone calendar.

## Explicitly Cut from the Hackathon

Email and all other account registration/login/recovery; cloud databases/storage; archived letters; user-facing letter classification/organization; chatbox and voice questions; saved chats or summaries; in-app calendar; calendar synchronization; cross-device account/history acceptance; automatic urgency-based reminder recommendations. A manually selected reminder date is sufficient for this demo.

## What "Working" Looks Like

An operator clones the repository, supplies their own API settings, runs the local relay and installs the app. They photograph a fictional letter, handle a photo-check result, obtain real analysis, review an action and save it as a correctly dated event in the iPhone calendar. Canceling does not claim success. An all-day event is actually marked all-day. No login, archive or chat demonstration is required.

## Future Commercial Roadmap

1. Build an in-app calendar and synchronize it with the phone calendar. Direction, ownership, conflicts and duplicate handling need a future design.
2. Add an account/login system. Authentication method is not fixed; email is a possible later implementation, not a current dependency.
3. Add a chatbox for questions and follow-up discussion about letters.
4. Save conversation-related records: the letter summary, extracted information, a summary of the user's questions, and a summary of the calendar items added. Full verbatim transcript storage, original-photo retention and cross-device behavior require future decisions; they are not assumed from this request.

5. Add letter classification to help users organize and browse letters by type. Categories and correction behavior need a future design.
6. Expand multilingual support beyond English and Chinese. Target languages and coverage across source letters, interface, explanations and speech will be defined in future planning; the hackathon retains its existing English-letter input and English/Chinese output.

These are product expansion opportunities, not claims of validated demand, revenue or completed functionality.

## Approval & Handoff

The learner's October 2 instruction directly approves this scope revision. Retain existing SwiftUI/camera/analysis/calendar implementation and earlier accepted UI refinements. Update PRD, spec and checklist to this boundary. GitHub publication and license readiness are separate shipping work; no push or release is implied by this planning change.

## October 2 — UI and Alert Follow-up

The learner requested a clearer UI, removal of the decorative envelope logo, explicit alerts and more notification options. These refinements remain within the core loop. The later usability review identified calendar-review complexity, event-date versus notification-time confusion, and app/system language transitions as open concerns. Record proposed improvements and target-user validation separately from implemented behavior; do not expand this revision into accounts, archives, chat or synchronization.

Calendar refinements also include editable event dates and time zones (default phone zone) for all event types, bill identity in calendar titles/notes, and original source deadlines retained when the user schedules a different date. These changes remain within the existing review-and-add loop.

October 4 language/output revision: new analysis generates only the selected app language (English or Simplified Chinese), including explanations, action descriptions, conditions and calendar titles/notes. The request sends `language`; provider structured-output schemas contain only that language. Source quotes retain their original language. A local adapter repeats the selected text into the legacy wire fields for client compatibility; it does not translate or consume generation tokens. Previously generated bilingual results are unchanged. App language follows the app-specific language preference, which can override the phone language.
