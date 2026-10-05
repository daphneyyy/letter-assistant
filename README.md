# Letter Assistant

An iPhone hackathon demo that turns an English medical/health-insurance letter, bank/credit-card statement or everyday bill/fee notice into a plain-language English or Chinese explanation and a reviewed phone-calendar event.

**Photograph → check the photo → analyze the letter → add to the iPhone calendar.**

No email, signup, login, database or chat history is required. Clone the source and use your own AI API key. The current demo runs as a Debug app installed with Xcode, with a local relay running on your Mac; it is not an App Store release or hosted service.

## What it does

Supported everyday documents now include utility bills (electricity/gas/water), telephone/internet bills, membership/subscription fee or renewal notices and other household/service charges. The explanation distinguishes the actual outstanding balance from total charges, credits and payments already received; scheduled automatic debits are not manual-payment requests. Renewal/charge dates are not cancellation deadlines. Only source-stated actions and cutoffs are offered for reviewed calendar creation. Bank checking/savings and credit-card statements are also supported: account balances and transaction totals are not payment instructions; minimum payment and full statement balance are explained separately. Investment/retirement reports and non-health insurance policy documents remain unsupported. This app explains documents and creates reviewed reminders; it does not pay bills or cancel services.

- Native iPhone camera, ordered multi-page capture and individual retakes.
- On-device readability checks, with Retake / Use anyway for uncertain quality. These checks do not call AI or check cropping/page numbering.
- Source-grounded bilingual explanations: what the letter says, what to pay attention to, actions/choices and relevant timing.
- Review and create all-day deadlines/reminders or timed appointments in the iPhone calendar. Tap Add to calendar to save directly to the default calendar; first use requests write-only permission.
- Concise calendar notes with an in-app preview, separate from source excerpts and review instructions.
- A clearly labeled no-AI calendar test entry with fictional examples.

Photos and analysis stay in the current session. Finishing or restarting does not save an archive. Events you save remain in Calendar and can be changed or removed there.

## Requirements

- A Mac and Xcode supporting your iPhone's iOS version; app deployment target is iOS 17+.
- An iPhone for real camera and calendar acceptance, with development signing/Developer Mode configured as required by Xcode.
- Deno 2.x on the Mac; the project has been tested with 2.9.6.
- Your own API key and a vision model supporting the OpenAI-compatible Chat Completions endpoint and this app's structured JSON-schema output.
- Phone and Mac on the same trusted local network for this demo.

No Supabase or email-service setup is needed. The `supabase/functions/_shared/` folder holds shared AI modules used by the local relay; it does not require running Supabase.

## Clone and configure your own key

Clone this GitHub repository, then open a terminal in the repository root. Create your local configuration:

```sh
cp .env.example .env.local
cp ios/Config/Debug.example.plist ios/Config/Debug.local.plist
openssl rand -hex 32
```

Copy the random token printed by the last command into both `DEV_ACCESS_TOKEN` in `.env.local` and `RELAY_TOKEN` in `ios/Config/Debug.local.plist`. They must match. This protects your local relay; it is not a user account or login.

Edit `.env.local`:

```dotenv
AI_BASE_URL=https://openrouter.ai/api/v1
AI_MODEL=your-compatible-vision-model
AI_API_KEY=your-own-api-key
AI_FREE_ONLY=true
DEV_ACCESS_TOKEN=your-generated-local-token
RELAY_HOST=your-macs-private-ipv4-address
RELAY_PORT=8787
```

Replace every placeholder. `AI_BASE_URL` is the provider's base URL without `/chat/completions`. With `AI_FREE_ONLY=true`, select an OpenRouter `:free` vision model; availability and quotas vary. To use a paid model or another compatible provider, explicitly set `AI_FREE_ONLY=false`; your provider may charge your account. The code never automatically falls back to a paid service. The model in `.env.example` is only an example, not an availability guarantee.

For a physical phone, set `RELAY_HOST` to your Mac's private IPv4 address and `RELAY_URL` in the local plist to `http://that-address:8787`. For the simulator, use `127.0.0.1` in both. Do not bind the relay to `0.0.0.0` or publish it on the internet.

`.env.local` and `Debug.local.plist` are ignored by Git. The provider API key stays on your Mac; the phone receives only the local relay token. Never put your provider key in the plist or commit local configuration.

## Run on your iPhone

1. Run the relay from the repository root:

   ```sh
   deno task relay
   ```

2. Open `ios/LetterAssistant.xcodeproj` in Xcode. Select the **LetterAssistant** scheme and **Debug** configuration.
3. In Signing & Capabilities, select **your own development team** and, if needed, a unique bundle identifier. Do not assume the repository's existing team settings work for your account.
4. Select your connected iPhone and run the app. Allow camera/local-network access when requested.
5. The interface uses the app language chosen in iPhone Settings, or follows the phone's language preferences when no app override is set (English or Simplified Chinese, with English as the fallback). The globe button opens the app's system Settings page; choose **Language / Preferred Language** there. Changing the system app language restarts the app and clears the unsaved letter, so finish reading first. Photograph a fictional letter, handle its photo check, and finish capture for analysis. The Mac relay must remain running.
6. Under an action, tap **Review calendar event / 查看并添加到日历**, review the proposal, then tap **Add to calendar / 添加到日历**. Allow calendar adding permission on first use; no second editor opens.

Restart the relay after changing API settings. Rebuild/reinstall the app after changing the local plist. Test builds package Debug.local.plist; Prod builds package Prod.local.plist. Both are ignored local files and must be configured before rebuilding; a successful build alone does not configure the AI connection.

This local HTTP phone-to-Mac path is for trusted-network demos with fictional letters. Interpretation sends the photos to the provider you configure over HTTPS. There is no shared project API key or central photo archive.

## Test the calendar without AI

On the Debug home screen expand **Demo tools / 演示工具**, then tap **Test calendar without AI / 日历测试（无需 AI）**. Choose a deadline, a reminder without a deadline, or an appointment. No photo, key or running relay is needed. Titles are marked `[TEST]` / `【测试】`; tapping Add creates a real event.

Deadlines/reminders are all-day events. All event types offer editable dates and time zones, defaulting to the phone zone. Source-zoned appointment instants are converted to the phone zone for display; changing the picker zone preserves the displayed day/clock. Moving a deadline event to another date preserves its original deadline in notes. Bill titles and notes retain bill type, organization and confirmed linked payment amount. Explicitly extracted appointment times now prefill the review; missing or ambiguous times still need entry, and the phone time zone is disclosed when none is stated. Appointment time and time zone must still be checked; Timed appointments use the AI-suggested duration when available, clearly labeled as an estimate, with a 30-minute fallback. Choose a duration preset or enter 1–1,440 custom minutes; the review shows the resulting end time. Choose an alert during review: all-day events default to 9 AM on the event date, and appointments default to 15 minutes before. Options include additional advance reminders, None, and a custom date/time. Custom alerts keep their exact date/time when the event date changes. Adjust alerts in the app before adding. Not now dismisses without saving. Permission denial offers Settings; an unavailable default calendar or a save error keeps the form available. Unknown/interrupted outcomes ask you to check Calendar before retrying to avoid duplicates. Later changes are made in Calendar.

## Verification and known limits

```sh
deno task check
deno task test
xcrun simctl list devices available
xcodebuild -project ios/LetterAssistant.xcodeproj -scheme LetterAssistant -destination 'platform=iOS Simulator,name=YOUR_INSTALLED_IPHONE_SIMULATOR' -derivedDataPath /tmp/letter-assistant-build CODE_SIGNING_ALLOWED=NO test
```

Replace the simulator-name placeholder with an installed device. The test suites cover capture state, image quality, contracts/provider failures, date policies, all-day EventKit construction and calendar field-validation/cancel UI. Mock-provider tests do not establish real AI accuracy.

Recorded development evidence includes successful backend checks, iOS unit/UI tests and signed phone builds. The all-day time-zone bug has a passing regression test and an installed fix; the learner's real-phone retry is still pending. Conditional enrollment extraction remains a known reliability concern despite successful individual runs. Provider quotas may block real analysis. Photos/results are not persisted, urgency-based reminder recommendations are not implemented, and the demo does not include chat or synchronization.

See `devpost/checklist.md` for current acceptance work and `devpost/build-history.md` for historical evidence. The build is not claimed fully accepted merely because it compiles.

## Future commercial direction

- An in-app calendar synchronized with the phone calendar.
- An account/login system.
- A chatbox for letter-related questions.
- Letter classification for organizing and browsing letters by type.
- Multilingual support beyond the hackathon’s English and Chinese; supported languages and coverage to be defined.
- Saved letter summaries, extracted information, summaries of the user's questions, and summaries of calendar items added.

These features are outside the hackathon. Their storage, authentication and synchronization design is future work, not a requirement for running this demo.

## Open-source publication readiness

The intended distribution is a public GitHub repository with operator-owned API keys. An open-source license still needs to be selected and added before publication. Audit tracked files and Git history for credentials, local signing/configuration, private learner context and real letter images before pushing publicly. Only fictional fixtures should be published. This requirements revision does not publish the repository.


### Test and Prod builds

Choose a scheme in Xcode before Run (automated tests use `LetterAssistant-Test`):

| Scheme | Configuration | Photo and demo tools | AI connection |
| --- | --- | --- | --- |
| `LetterAssistant-Test` | Debug, `TEST_BUILD` | Test photos on simulator or phone; fictional calendar tools | Ignored `ios/Config/Debug.local.plist` |
| `LetterAssistant-Prod` | Release | Camera capture only; no test photos bundled or demo tools | Ignored `ios/Config/Prod.local.plist` |

Test is labeled **Letter Assistant Test** on the device. Prod is labeled **Letter Assistant**. Both currently use the same bundle ID, so installing one replaces the other. The existing `LetterAssistant` scheme retains its Debug-run/Release-archive behavior.

For Prod connection settings, copy `ios/Config/Prod.example.plist` to `ios/Config/Prod.local.plist` and set your relay URL/token. Prod accepts HTTPS or the existing trusted local-network HTTP relay; Test retains its local HTTP relay. The build copies only the selected environment's configuration. Missing configuration shows an honest setup message; there is no automatic fallback to Test credentials. This separates app builds and test assets; it does not deploy a production backend.

New analysis generates explanations and calendar text only in the selected app language (English or Simplified Chinese), saving the second-language generation. Source quotations keep their original language. App-specific language settings can override the phone language.
