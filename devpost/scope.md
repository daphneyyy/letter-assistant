---
doc: scope
status: approved
---

# Letter Assistant — Hackathon Scope

Approved revision: October 2, 2026. The learner explicitly narrowed the hackathon to capture → photo checks → analysis → user-confirmed iPhone calendar creation. This replaces the previous account/archive/chat scope; those features are future commercial work, not unfinished hackathon requirements.

## The Unique Kernel

Help middle-aged and older immigrants with limited English understand a medical or health-insurance letter: what it says, what to pay attention to, what actions or choices it contains, and when. Turn an applicable action into an event the user reviews and saves in the phone calendar.

## Who It's For

People who struggle to read English medical and health-insurance letters. The interface and explanations support English and Simplified Chinese, with large readable text and spoken capture guidance.

## The Core Loop

1. Open the app and choose English or Chinese. No registration or login.
2. Photograph one or more pages using the iPhone camera.
3. Check readability locally; retake unreadable images, or explicitly accept uncertain quality.
4. Finish capture to analyze the ordered pages using the operator's own AI API key.
5. Read the explanation and source-backed facts, actions and relevant dates.
6. Review an action and its calendar date, then save or cancel in Apple's calendar editor.

## The POC Boundary

- Native iPhone app, local photo checks, temporary ordered multi-page capture and per-page retakes.
- AI interpretation of medical/health-insurance letters, bilingual output and visible uncertainty.
- Creation-only iPhone calendar handoff: deadlines, user-selected reminder dates, and user-verified appointments.
- No-AI fictional calendar examples for testing, clearly labeled as tests.
- Open-source, clone-and-run distribution on GitHub; each operator supplies their own compatible API key and model configuration.
- Current run mode: Mac-hosted local relay plus an iPhone Debug build installed with Xcode. No hosted shared service is promised.
- Photos and analysis stay in the active session; finishing/restarting does not provide an archive. Saved calendar events remain in the phone calendar.

## Explicitly Cut from the Hackathon

Email and all other account registration/login/recovery; cloud databases/storage; archived letters; chatbox and voice questions; saved chats or summaries; in-app calendar; calendar synchronization; cross-device account/history acceptance; automatic urgency-based reminder recommendations. A manually selected reminder date is sufficient for this demo.

## What "Working" Looks Like

An operator clones the repository, supplies their own API settings, runs the local relay and installs the app. They photograph a fictional letter, handle a photo-check result, obtain real analysis, review an action and save it as a correctly dated event in the iPhone calendar. Canceling does not claim success. An all-day event is actually marked all-day. No login, archive or chat demonstration is required.

## Future Commercial Roadmap

1. Build an in-app calendar and synchronize it with the phone calendar. Direction, ownership, conflicts and duplicate handling need a future design.
2. Add an account/login system. Authentication method is not fixed; email is a possible later implementation, not a current dependency.
3. Add a chatbox for questions and follow-up discussion about letters.
4. Save conversation-related records: the letter summary, extracted information, a summary of the user's questions, and a summary of the calendar items added. Full verbatim transcript storage, original-photo retention and cross-device behavior require future decisions; they are not assumed from this request.

These are product expansion opportunities, not claims of validated demand, revenue or completed functionality.

## Approval & Handoff

The learner's October 2 instruction directly approves this scope revision. Retain existing SwiftUI/camera/analysis/calendar implementation and earlier accepted UI refinements. Update PRD, spec and checklist to this boundary. GitHub publication and license readiness are separate shipping work; no push or release is implied by this planning change.
