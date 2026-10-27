---
doc: scope
status: approved
---

# Letter Assistant — Hackathon Scope

The approved hackathon scope is capture → local photo checks → analysis → reviewed iPhone calendar creation. Supported documents include medical/health-insurance letters, bank/credit-card statements and everyday bills or fee/renewal notices. Investment/retirement reports and non-health insurance policy documents remain outside scope.

## The Unique Kernel

Help people turn complex or unfamiliar letters into clear understanding and next steps: what the document means, which amounts and conditions matter, whether action is needed, and when. The need can arise from unfamiliar terminology, confusing document structure, multiple amounts or dates, or a language preference—not only limited English proficiency. Turn an applicable action into an event the user reviews and saves in the phone calendar.

## Who It's For

Anyone who wants help understanding supported letters and managing their next steps, including fluent English readers dealing with unfamiliar medical, financial or billing terms and people who prefer an explanation in Chinese. Age, immigration status and English proficiency do not define eligibility or the product audience.

The current demo accepts English source documents and offers the interface, explanations and calendar text in English or Simplified Chinese, selected through the app language setting. It generates the selected language for each analysis rather than both languages simultaneously. Future versions can expand to additional languages; source-document, interface, explanation and speech coverage will need separate definition and verification.

Large readable text and spoken capture guidance support accessibility across the audience. Independent-use usability has not been established across representative users; automated checks do not prove it. Technical clone/setup is performed by an operator; the current demo is not a self-installable consumer product.

## The Core Loop

1. Open the app in English or Simplified Chinese, using the app-specific iPhone language setting or the phone preference. No registration or login.
2. Photograph pages using the iPhone camera, select existing photos, or import a PDF; review the pages in order.
3. Check readability locally; retake unreadable images, or explicitly accept uncertain quality.
4. Tap Analyze document / 分析文档 to analyze the ordered pages using the operator's own AI API key.
5. Read the explanation and source-backed facts, actions and relevant dates.
6. Review an action and its calendar date, then tap Add to save directly to the default iPhone calendar (write-only permission), or dismiss without adding.

## The POC Boundary

- Native iPhone app, local photo checks, temporary ordered multi-page capture, photo-library/PDF import and per-page retakes.
- AI interpretation of medical/health-insurance letters, bank/credit-card statements and everyday bills/fee or renewal notices, output in the selected English or Simplified Chinese app language and visible uncertainty. Everyday billing includes electricity/gas/water, telephone/internet, memberships/subscriptions and other household/service charges. Paid balances and scheduled automatic debits do not imply a manual-payment task; renewal dates do not imply a cancellation deadline.
- Editable event dates and time zones, source-grounded bill titles/notes, and original deadlines retained in notes when scheduling on another date. Explicit clock cutoffs use timed markers in the source zone; date-only deadlines remain all-day.
- Creation-only iPhone calendar handoff: deadlines, editable personal reminders initially set to tomorrow, and user-reviewed appointments. The review includes user-controlled notification alerts with presets, None, and a custom date/time, saved directly after tapping Add; no second system review. These settings do not infer urgency from the letter.
- Test/Debug-only no-AI fictional calendar examples, clearly labeled as tests; saving them creates real calendar events.
- Payment execution, automatic cancellation and recurring event creation are outside scope.
- Open-source, clone-and-run distribution on GitHub; each operator supplies their own compatible API key and model configuration.
- Current demo setup: Mac-hosted local relay plus an iPhone Test/Debug build installed with Xcode. A separate Prod/Release scheme uses its own local configuration and excludes demo tools/fixtures. No hosted shared service is promised.
- Photos and analysis stay in the active session; finishing/restarting does not provide an archive. Saved calendar events remain in the phone calendar.

## Explicitly Cut from the Hackathon

Email and all other account registration/login/recovery; cloud databases/storage; archived letters; user-facing letter classification/organization; chatbox and voice questions; saved chats or summaries; in-app calendar; calendar synchronization; cross-device account/history acceptance; automatic urgency-based reminder recommendations. A manually selected reminder date is sufficient for this demo.

## What "Working" Looks Like

An operator clones the repository, supplies their own API settings, runs the local relay and installs the app. They photograph a fictional letter, handle a photo-check result, obtain real analysis, review an action and save it as a correctly dated event in the iPhone calendar. Canceling does not claim success. Date-only deadlines and personal reminders are actually marked all-day; explicit clock cutoffs use timed markers. No login, archive or chat demonstration is required.

## Future Commercial Roadmap

1. Build an in-app calendar and synchronize it with the phone calendar. Direction, ownership, conflicts and duplicate handling need a future design.
2. Add an account/login system. Authentication method is not fixed; email is a possible later implementation, not a current dependency.
3. Add a chatbox for questions and follow-up discussion about letters.
4. Save conversation-related records: the letter summary, extracted information, a summary of the user's questions, and a summary of the calendar items added. Full verbatim transcript storage, original-photo retention and cross-device behavior require future decisions; they are not assumed from this request.

5. Add letter classification to help users organize and browse letters by type. Categories and correction behavior need a future design.
6. Expand multilingual support beyond English and Chinese. Target languages and coverage across source letters, interface, explanations and speech will be defined in future planning; the hackathon retains its existing English-letter input and English/Chinese output.

These are product expansion opportunities, not claims of validated demand, revenue or completed functionality.

## Approval & Handoff

This scope is approved. The PRD, technical specification and build checklist define the current capture/analysis/calendar implementation and acceptance work. The project uses MIT; the repository is public as verified through GitHub metadata on 2026-10-26. Publication is separate from planning and local development.
