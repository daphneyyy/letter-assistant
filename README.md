# Letter Assistant

An iPhone app that helps people understand letters, identify relevant actions and dates, and optionally save a reviewed event to their phone calendar. It is for anyone who wants clearer guidance through complex or unfamiliar paperwork, regardless of English proficiency, age or background.

The app accepts English medical/health-insurance letters, bank/credit-card statements and everyday bills/fee notices. Users can choose English or Simplified Chinese explanations and calendar text through the app language setting. Support for additional languages is planned for future versions; it is not implemented in this version.

**Photograph → check the photo → analyze the letter → add to the iPhone calendar.**

No email, signup, login, database or chat history is required. Clone the source and use your own AI API key. The app runs as a Debug app installed with Xcode, with a local relay running on your Mac; it is not an App Store release or hosted service.

## Getting started

This is a source-built iPhone prototype. Using AI interpretation requires a Mac, Xcode, an iPhone and your own provider account. There is no shared API key.

### Start with a free OpenRouter model

1. Sign in or create an account at [OpenRouter](https://openrouter.ai/), then open [API Keys](https://openrouter.ai/keys) and create a key for Letter Assistant. Copy it into `AI_API_KEY` in your ignored `.env.local` file. Creating a key does not make every model free.
2. Follow [Clone and configure your own key](#clone-and-configure-your-own-key) below, including the separate random relay token and the iPhone connection plist.
3. For the free path, use:

   ```dotenv
   AI_BASE_URL=https://openrouter.ai/api/v1
   AI_MODEL=dots-studio/dots-3-note-preview:free
   AI_API_KEY=your-openrouter-key
   AI_FREE_ONLY=true
   ```

4. Check the [current model catalog](https://openrouter.ai/models) before running. The example is listed with image input and structured outputs as of October 25, 2026; this is not a successful live-analysis claim. If unavailable, choose another explicit `vendor/model:free` ID supporting **both image input and JSON Schema structured output**, including support at its serving endpoint. A text-only model cannot interpret these photos. This app's free-mode guard intentionally rejects `openrouter/free` and other automatic model routers; select an explicit compatible model.
5. Run `deno task relay`, then build and run **LetterAssistant-Test** as described in [Run on your iPhone](#run-on-your-iphone). Keep the relay running during analysis.

Free models have [account/model quotas and availability limits](https://openrouter.ai/docs/api_reference/limits). A free endpoint may be busy or unavailable even with a valid key. The app requests zero-price routing in free mode and never silently switches to a paid model. Wait or select another compatible free model if needed. OpenRouter's [quickstart](https://openrouter.ai/docs/quickstart) and [structured-output documentation](https://openrouter.ai/docs/guides/features/structured-outputs) describe provider setup and endpoint requirements.

### Optional: use your preferred model and API

A stronger compatible vision model **may** improve extraction quality and reliability; the API key itself does not improve results. No comparative quality benchmark is claimed. Paid access is optional and may incur charges on your account.

Edit these four settings in `.env.local` and restart the relay:

| Setting | What to enter |
| --- | --- |
| `AI_BASE_URL` | Your provider's HTTPS Chat Completions base URL, without `/chat/completions` |
| `AI_MODEL` | The provider's exact vision model ID |
| `AI_API_KEY` | A key issued by that provider |
| `AI_FREE_ONLY` | `true` for explicit OpenRouter `:free` models; `false` for a paid model or another compatible provider |

For a paid OpenRouter model, keep `AI_BASE_URL=https://openrouter.ai/api/v1`, enter its model ID and your OpenRouter key, and set `AI_FREE_ONLY=false`. For another provider, replace the base URL, model and key together. The relay appends `/chat/completions`, uses `Authorization: Bearer ...`, sends inline JPEG images and requires `response_format` with strict `json_schema`. It does not accept a full endpoint URL, HTTP provider URLs, URL credentials/query parameters, arbitrary authentication headers, or a different native API protocol. Those integrations require a transport adapter. OpenRouter-specific routing fields are omitted for other providers.

Switching the provider/model/key requires no Swift changes or app rebuild. Only changing the phone-to-relay URL/token requires updating the local plist and rebuilding. The provider key stays on the Mac. Legacy `OPENROUTER_*` and `OPENAI_*` settings are retained for earlier development setups; new setups should use the unified `AI_*` settings above, which take precedence and never borrow a legacy provider key.

### Try the app with your own photos

1. Photograph your own English letter or choose a picture from your iPhone photo library. Use a supported medical/health-insurance letter, bank/credit-card statement, or everyday bill/fee notice.
2. Check that the text is readable. Retake unclear pages, and add any remaining pages in their original order before tapping **Analyze document**.
3. Read the explanation and compare names, amounts, actions and dates with your original letter. Distinguish an amount actually due from total charges, credits, payments already received or a scheduled automatic debit.
4. If an action offers a calendar event, review its date, time, time zone and alert, then tap **Add to calendar**. Open iPhone Calendar to check the saved event.
5. To try explanations in English or Simplified Chinese, change the app language in iPhone Settings before starting a new analysis. Changing the language restarts the app and clears the unsaved session.

Photo readability checks run on your phone. Tapping **Analyze document** sends the accepted photos to your configured AI provider. Photos and results remain in the current app session; saved calendar events remain in iPhone Calendar.

If setup fails, check the relay's safe error code: `provider_auth_failed` means check the selected provider key; `provider_rate_limited` means check quotas/wait; `free_model_required` means check the model ID/free-mode setting; `invalid_provider_configuration` means check the base URL/model; `invalid_ai_output` or `incomplete_ai_output` means the response failed this app's contract. `provider_unavailable` can include an unsupported endpoint/model or unavailable provider. For connection failures, check matching relay tokens, Mac/phone Wi-Fi, private IP and the running relay.

## What it does

Supported everyday documents now include utility bills (electricity/gas/water), telephone/internet bills, membership/subscription fee or renewal notices and other household/service charges. The explanation distinguishes the actual outstanding balance from total charges, credits and payments already received; scheduled automatic debits are not manual-payment requests. Renewal/charge dates are not cancellation deadlines. Only source-stated actions and cutoffs are offered for reviewed calendar creation. Bank checking/savings and credit-card statements are also supported: account balances and transaction totals are not payment instructions; minimum payment and full statement balance are explained separately. Investment/retirement reports and non-health insurance policy documents remain unsupported. This app explains documents and creates reviewed reminders; it does not pay bills or cancel services.

- Native iPhone camera, ordered multi-page capture and individual retakes.
- On-device readability checks, with Retake / Use anyway for uncertain quality. These checks do not call AI or check cropping/page numbering.
- Source-grounded explanations in the selected English or Chinese app language: what the letter says, what to pay attention to, actions/choices and relevant timing.
- Review and create all-day deadlines/reminders or timed appointments in the iPhone calendar. Tap Add to calendar to save directly to the default calendar; first use requests write-only permission.
- Concise calendar notes with an in-app preview, separate from source excerpts and review instructions.

Photos and analysis stay in the current session. Finishing or restarting does not save an archive. Events you save remain in Calendar and can be changed or removed there.

## Requirements

- A Mac and Xcode supporting your iPhone's iOS version; app deployment target is iOS 17+.
- An iPhone for real camera and calendar acceptance, with development signing/Developer Mode configured as required by Xcode.
- Deno 2.x on the Mac; the project has been tested with 2.9.6.
- Your own API key and a vision model supporting the OpenAI-compatible Chat Completions endpoint and this app's structured JSON-schema output.
- Phone and Mac on the same trusted local network for the local connection.

No Supabase or email-service setup is needed. The `supabase/functions/_shared/` folder holds shared AI modules used by the local relay; it does not require running Supabase.

## Clone and configure your own key

Clone the [Letter Assistant repository](https://github.com/daphneyyy/letter-assistant), then open a terminal in the repository root. Create your local configuration:

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

2. Open `ios/LetterAssistant.xcodeproj` in Xcode. Select the **LetterAssistant-Test** scheme (Debug configuration).
3. In Signing & Capabilities, select **your own development team** and, if needed, a unique bundle identifier. Do not assume the repository's existing team settings work for your account.
4. Select your connected iPhone and run the app. Allow camera/local-network access when requested.
5. The interface uses the app language chosen in iPhone Settings, or follows the phone's language preferences when no app override is set (English or Simplified Chinese, with English as the fallback). The globe button opens the app's system Settings page; choose **Language / Preferred Language** there. Changing the system app language restarts the app and clears the unsaved letter, so finish reading first. Photograph your own letter or choose your own picture from the photo library, check readability, and tap **Analyze document**. The Mac relay must remain running.
6. Under an action, tap **Review calendar event / 查看并添加到日历**, review the proposal, then tap **Add to calendar / 添加到日历**. Allow calendar adding permission on first use; no second editor opens.

Restart the relay after changing API settings. Rebuild/reinstall the app after changing the local plist. Test builds package Debug.local.plist; Prod builds package Prod.local.plist. Both are ignored local files and must be configured before rebuilding; a successful build alone does not configure the AI connection.

The local HTTP phone-to-Mac connection requires a trusted private network. Interpretation sends the photos to the provider you configure over HTTPS. There is no shared project API key or central photo archive.

## Review and save calendar events

Date-only deadlines/reminders are all-day events. Explicit clock deadlines use timed cutoff markers in the source time zone. All event types offer editable dates and time zones. Timed cutoffs initially use their source zone; other events initially use the phone zone. Source-zoned appointment instants are converted to the phone zone for display; changing the picker zone preserves the displayed day/clock. Moving a deadline event to another date preserves its original deadline in notes. Bill titles and notes retain bill type, organization and confirmed linked payment amount. Explicitly extracted appointment times now prefill the review; missing or ambiguous times still need entry, and the phone time zone is disclosed when none is stated. Appointment time and time zone must still be checked; Timed appointments use the AI-suggested duration when available, clearly labeled as an estimate, with a 30-minute fallback. Tap the duration value and use the hour/minute wheels to choose 1–1,440 minutes; the review shows the resulting end time. Choose an alert during review: date-only deadlines default to 9 AM the day before, undated personal reminders default to 9 AM on the chosen day, and appointments default to 1 day before. Options include additional advance reminders, None, and a custom date/time. Custom alerts keep their exact date/time when the event date changes. Adjust alerts in the app before adding. Not now dismisses without saving. Permission denial offers Settings; an unavailable default calendar or a save error keeps the form available. Unknown/interrupted outcomes ask you to check Calendar before retrying to avoid duplicates. Later changes are made in Calendar.

## Verification and known limits

```sh
deno task check
deno task test
xcrun simctl list devices available
xcodebuild -project ios/LetterAssistant.xcodeproj -scheme LetterAssistant-Test -destination 'platform=iOS Simulator,name=YOUR_INSTALLED_IPHONE_SIMULATOR' -derivedDataPath /tmp/letter-assistant-build CODE_SIGNING_ALLOWED=NO test
```

Replace the simulator-name placeholder with an installed device. The test suites cover capture state, image quality, contracts/provider failures, date policies, all-day EventKit construction and calendar field-validation/cancel UI. Mock-provider tests do not establish real AI accuracy.

Conditional enrollment extraction remains a known reliability concern. Provider quotas may block analysis. Photos/results are not persisted, urgency-based reminder recommendations are not implemented, and the app does not include chat or synchronization. Automated tests do not establish accuracy for your own letters; compare important details with the source before acting.

See [devpost/checklist.md](devpost/checklist.md) for current acceptance work and recorded development evidence. Earlier source changes are available in Git history. The build is not claimed fully accepted merely because it compiles.

## Development tools and third-party integrations

The project is developed with AI assistance in Codex using the [Devpost Learn Skill Pack](https://github.com/challengepost/learn-ai-basics). The generated planning documents are [scope.md](devpost/scope.md), [prd.md](devpost/prd.md), and [spec.md](devpost/spec.md); implementation and verification records are in [checklist.md](devpost/checklist.md). The offline [app map](devpost/app-map.html) traces capture, analysis and calendar creation; [shipping.md](devpost/shipping.md) records publication prerequisites and submission status.

| Tool or integration | Role in this project |
| --- | --- |
| Xcode and Apple SDK frameworks | SwiftUI/UIKit interface, camera/photo selection, Vision readability checks, PDFKit import, speech guidance and EventKit calendar creation |
| Deno | Runs the local TypeScript relay and its tests; runtime imports are repository-local modules |
| Operator-configured AI provider and vision model | Interprets images using the operator's own API account/key; the example configuration uses OpenRouter, and compatible endpoints are supported |

Operators must use the Apple SDKs, runtime and configured AI service/model in accordance with their respective terms. The project MIT license does not replace third-party terms or grant access to a provider account. No third-party model weights, provider credentials or Devpost Skill Pack source are bundled in the tracked application source.

The author confirms that no code or materials were copied or adapted from prior projects, tutorials, templates or other repositories, apart from the standard tools/frameworks and Devpost Learn Skill Pack documented above.

## Open-source publication readiness

This project is licensed under the [MIT License](LICENSE).

The [GitHub repository](https://github.com/daphneyyy/letter-assistant) is currently private and will be made public for submission. Operators supply their own API keys. Audit tracked files and Git history for credentials, local signing/configuration, private learner context and real letter images before pushing publicly. Public access and GitHub license detection must be checked after the visibility change.


### Test and Prod builds

Choose a scheme in Xcode before Run (automated tests use `LetterAssistant-Test`):

| Scheme | Configuration | AI connection |
| --- | --- | --- | --- |
| `LetterAssistant-Test` | Debug, `TEST_BUILD` | Ignored `ios/Config/Debug.local.plist` |
| `LetterAssistant-Prod` | Release | Ignored `ios/Config/Prod.local.plist` |

Test is labeled **Letter Assistant Test** on the device. Prod is labeled **Letter Assistant**. Both currently use the same bundle ID, so installing one replaces the other. The existing `LetterAssistant` scheme retains its Debug-run/Release-archive behavior.

For Prod connection settings, copy `ios/Config/Prod.example.plist` to `ios/Config/Prod.local.plist` and set your relay URL/token. Prod accepts HTTPS or the existing trusted local-network HTTP relay; Test retains its local HTTP relay. The build copies only the selected environment's configuration. Missing configuration shows an honest setup message; there is no automatic fallback to Test credentials. These settings select the app connection configuration; they do not deploy a backend.

New analysis generates explanations and calendar text only in the selected app language (English or Simplified Chinese), saving the second-language generation. Source quotations keep their original language. App-specific language settings can override the phone language.

The old AI photo-quality endpoint and prompts have been removed. Photo readability checks run locally on the iPhone; the relay offers only document interpretation.
