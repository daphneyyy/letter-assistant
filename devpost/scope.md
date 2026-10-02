---
doc: scope
status: approved
---

# Letter Assistant (Working Description)

Help middle-aged and older immigrants with limited English turn letters from hospitals or insurance companies into plain-language explanations of what to do next, in English or Mandarin Chinese.

## The Unique Kernel

“Don't translate the whole letter for me. Just tell me: what is this, do I need to deal with it, what should I do, and when?” Large text, voice guidance, and reminders support this core need.

## Who It's For

A middle-aged or older immigrant with limited English who receives a hospital or insurance bill or explanation letter. They recognize a few words but cannot make sense of the terminology, amounts, deadlines, or required actions. How they currently seek help has not been established.

## The Core Loop

The user registers with a verified email address plus password, chooses English or Chinese, and enters the chat home. They photograph a medical or insurance letter one page at a time, with spoken guidance and retakes for unclear or cropped pages. After capture, the tool explains the complete letter in large text in chat: what it is, what to do, and the deadline. The user can tap “Ask” for letter-grounded voice questions.

Every letter is archived with its original photos and a concise detail summary, whether or not action is required. Users browse Recipient → Category → letters sorted by date and can correct recipient names or categories. Each letter has its own persistent conversation, resumed from its detail page; the full history and archive are accessible across phones using the same account.

Users confirm actions for the phone's built-in calendar. Explicit deadlines use the stated deadline date, appointments use the stated date and time, and actions without deadlines use a user-confirmed all-day reminder date. Past dates are labeled as passed and never silently rescheduled. The user reviews and confirms a letter-generated event before creating it in the iPhone calendar. Later edits and alerts are managed in the system calendar. V1 has no in-app calendar, calendar synchronization, event reconciliation, or calendar conflict handling.

## Inspiration & Identity

Plain language in English or Mandarin Chinese, large text, and voice guidance help people unfamiliar with English and technology complete the task. The initial inspiration was a YC topic about opportunities for AI applications serving older adults and nontechnical users. No specific source was provided; this is the learner's motivation, not a validated market conclusion.

## Why This Matters to the Learner

The learner wants to explore “AI for elderly” and has narrowed the intended audience to middle-aged and older immigrants who struggle to understand English letters from hospitals and insurers.

## What "Working" Looks Like

The demonstrator captures a multi-page English medical or insurance letter, retakes an invalid page, and receives an English or Chinese explanation of the letter type, action, relevant amounts, stated deadline, and consequences explicitly written in the letter. They ask a voice question, reopen the archived letter's original photos and summary, and resume its conversation.

The demonstrator reviews and confirms a letter-generated event, saves it in the iPhone calendar, and manages subsequent changes there. The letter retains its original facts. They also show a letter with no action still being archived, an ambiguous category being reviewed, and the same account's archive and full letter-specific chat history being accessible on another phone. Detailed verification scenarios are in `prd.md > Demonstration and Acceptance`.

## The POC Boundary

The approved first version includes:

- English medical and insurance letters, with English or Mandarin Chinese explanations and written Chinese output.
- Minimalist chat home, large text, bottom capture control, and Chat/Archive tabs.
- Guided page-by-page capture, photo validation and retakes, whole-letter interpretation, and button-initiated voice questions.
- Email-only signup, email verification, email-and-password login, and password recovery by email; same-account archive/conversation access across phones. Phone-number authentication is deferred.
- Archived original photos and summaries, recipient corrections, and one primary visible category per letter: Bills, Insurance explanations, Appointments, Test results, or Medications. Ambiguous classifications enter a temporary Needs review state rather than a sixth category. Unknown person is a recipient fallback, not a category.
- A detail page showing a concise summary by default and access to the letter's persistent conversation; full letter-specific history syncs across phones.
- Language choice after registration and changes in Settings, including the language of existing summaries.
- User-reviewed and confirmed creation of letter-generated events in the iPhone calendar. Later changes and alerts are managed there; deadline, appointment, and reminder dates remain distinct.
- Simple recovery actions for empty, processing, interpretation/voice failure, and calendar cancellation/failure states.

Explanations must be grounded in the provided letter and must not invent consequences it does not state. Unconfirmed amounts, dates, or actions must be marked for verification. Missing deadlines remain missing even when AI suggests a reminder date. An insurance explanation must not automatically be interpreted as “no payment required.”

The original learning target was approximately 2–4 hours of active work, with a short demo and a public GitHub repository; deployment is optional. The approved PRD adds accounts, archiving, and full conversation synchronization, so that original time target is not a validated estimate for the expanded scope. `4-spec` must assess effort and discuss any needed tradeoffs with the user rather than silently removing approved requirements.

## Later

Government, banking, transportation, and other letter domains. A separate Google Calendar integration is also deferred; V1 prioritizes the phone's built-in calendar. The learner selected iPhone during technical planning; the revised spec uses the EventKitUI creation editor without ongoing event access.

## Explicitly Cut

- Word-for-word translation as the primary output; the priority is actionable explanations.
- An in-app Calendar tab, bidirectional event editing, cross-device calendar synchronization, event reconciliation, or calendar conflict handling.
- A task-completion tracker, reminder popups, or independent phone notifications.
- Phone-number authentication, including SMS signup, verification, login, and recovery.
- Phone/email linking and account merging in V1.
- Cross-account family sharing; filing under multiple recipient names does not imply shared accounts.

## Approval & Handoff

The learner approved the original scope and subsequently approved the complete English PRD on September 30, 2026. This scope has been aligned with that approved document, including the replacement of in-app to-dos with calendar handoff and the additions of accounts, archiving, and persistent cross-phone conversations.

`3-prd` is complete. `4-spec` is complete; `spec.md` contains the approved technical blueprint and expanded effort estimate. `5-build` is next. `prd.md` contains the detailed approved behaviors and acceptance criteria.

## Agreed Changes During Technical Planning

The learner selected iPhone as the first supported platform and agreed to a native Swift + SwiftUI app. Cloud services and a small testing budget are acceptable. The learner agreed to Supabase for email authentication, database, and private photo storage. The learner agreed to call OpenAI through the backend for letter-image interpretation and letter-grounded questions, including sending letter photos to OpenAI for processing. API credentials stay on the backend. The approved spec defines the initial model candidate and Resend email delivery setup; account access, domain verification, and actual costs still require build-time checks. The learner explicitly narrowed V1 to email registration, email verification, password login, and password recovery by email. Phone/SMS registration is deferred. Same-account access across iPhones remains required. These amendments preserve the approved status of this document; the learner subsequently approved the full technical specification on September 30, 2026, including Resend email delivery and the documented implementation defaults and limits. See `spec.md` for the approved blueprint and outstanding build prerequisites.

## V1 Simplification During Build Planning

The learner explicitly revised V1: email-only signup, verification, email/password login, and email password recovery; phone-number authentication is deferred. Calendar support is limited to reviewing, confirming, and creating letter-generated events in the iPhone calendar, with later changes managed there. The prior in-app calendar proposal is superseded, including bidirectional editing, cross-device calendar synchronization, event reconciliation, and calendar conflict handling.

The first build milestone proves capture of one fictional letter → photo validation → real AI interpretation before authentication or archive persistence. Accessibility starts in that milestone: large Dynamic Type, readable Chinese text, large tap targets, and basic VoiceOver support. Needs review is a classification state, not a sixth category; Unknown person is a recipient fallback, not a category. Cross-device archive and conversation behavior is verified once at final acceptance, not as a physical-device prerequisite for each slice. The final product retains email accounts and persistent archives/conversations. The checklist remains draft pending review of the revised build order.


Provider clarification (October 1, 2026): the learner uses an OpenRouter free API key. The build now routes AI image requests through OpenRouter to a pinned free vision model, with no paid fallback. This supersedes the earlier direct-OpenAI provider choice while preserving the product scope, backend-only credentials, and build order. Only fictional letters are used during development.
