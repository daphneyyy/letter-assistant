# Letter Assistant

An iPhone proof of concept that explains fictional medical and insurance letters in English or Chinese: **what this is → what to do → when**.

## Current milestone

Slice 1 is in progress: temporary multi-page capture, local readability checks, spoken capture guidance, an OpenRouter integration using a free vision model, and an accessible explanation screen. Photos and results stay in memory for this slice. Accounts, archive, voice questions, and calendar creation belong to later slices. Debug and Release simulator builds, eleven unit tests, one Chinese large-text UI test, and twenty-one relay tests pass. The OpenRouter key is verified. The fictional bill now passes real photo validation and interpretation through the local relay (both HTTP 200), with the expected USD 125.00 payment and 2026-11-15 deadline in both languages. A direct successful interpretation reported cost 0. Remaining fixture cases and physical-device acceptance are pending. The earlier 401 came from sending an OpenRouter key to the wrong provider.

## Run the first slice

1. Open `ios/LetterAssistant.xcodeproj` in Xcode and select the shared **LetterAssistant** scheme.
2. Configure the local relay below. The simulator uses `http://127.0.0.1:8787`. For a physical iPhone, connect it to Xcode, choose your signing team and a unique bundle identifier, and use the Mac's private LAN address in both settings files. The phone and Mac must be on the same trusted network. Never expose this development relay publicly.
3. Start the relay, then press **Run** in Xcode. Choose English or 中文. Photograph a printed fictional letter from `fixtures/letters/`, keeping all page edges visible. The simulator has a clearly labeled fictional-sample button because it has no physical camera. After validation, use Add fictional next page (simulator) to append the bundled continuation page, then Finish taking photos.
4. An accepted page enables **Photograph next page** and **Finish taking photos**. Next page preserves earlier originals; finish interprets all accepted pages together. Printed page numbering is not checked. Use page selectors to review or retake a captured page. Rejected/uncertain pages require a retake. Connection/provider failures keep the photo and offer retry. An absent key produces an honest setup error, not a sample interpretation.

The target phone is user-reported as iPhone 18 Pro. Device connection, OS compatibility, signing, actual camera quality, and audio/VoiceOver behavior must be checked on that phone before slice 1 passes. If its OS is newer than the installed Xcode supports, update Xcode before device installation.

## Local relay configuration

The relay requires Deno 2.x; verified locally with 2.9.6. It uses TypeScript and native fetch with no third-party runtime imports.

- `.env.local` holds the **OpenRouter API key on the Mac only**, model name, temporary relay token, and bind address. The ignored local file is configured for this workspace. For a fresh checkout, copy `.env.example` to `.env.local`.
- `ios/Config/Debug.local.plist` holds only `RELAY_URL` and the temporary `RELAY_TOKEN`. For a fresh checkout, copy `Debug.example.plist` and replace the placeholder. Use a random token of at least 32 characters in both files. These local files are ignored by Git.
- Use an [OpenRouter API key](https://openrouter.ai/settings/keys) in `OPENROUTER_API_KEY`; never paste it in chat. The pinned free vision model is `dots-studio/dots-3-note-preview:free`. Only `:free` models are accepted on this path, with zero token/request/image price ceilings and no automatic provider fallback. Free capacity and account quotas may cause retryable errors. Structured output is validated locally before display. See [OpenRouter routing](https://openrouter.ai/docs/guides/routing/provider-selection).
- For a physical phone, set `RELAY_HOST` to the Mac's explicit private IPv4 address (not `0.0.0.0`) and `RELAY_URL` to `http://that-address:8787`. The local HTTP transport is solely for this fictional-data development milestone. The development connection file is copied into Debug builds only; Release excludes it and disables this path.

```sh
deno task relay
```

If Deno is not installed, this session used a temporary npm-provided runtime:

```sh
npm --cache /tmp/letter-assistant-npm exec --yes --package=deno@2.9.6 -- deno task relay
```

The relay requires its development token, refuses public/wildcard bind addresses, bounds image bodies to 10 MiB, and allows one active request. Validation expires after 15 minutes; interpretation must use the same accepted photo bytes. Usage logs contain only model/input/output token counts. There is no database or image logging. Stop with Control-C. Rebuild the app after changing its local connection settings.

## Verification

Installed toolchain: Xcode 26.5 (17F42), Swift 6.3.2, iOS 26.5 simulator. The project supports iOS 17+ and uses no third-party Swift packages in slice 1.

```sh
xcodebuild -project ios/LetterAssistant.xcodeproj -scheme LetterAssistant -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/letter-assistant-build CODE_SIGNING_ALLOWED=NO build
xcodebuild -project ios/LetterAssistant.xcodeproj -scheme LetterAssistant -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/letter-assistant-build CODE_SIGNING_ALLOWED=NO test
deno task check
deno task test
```

Use an installed simulator from `xcrun simctl list devices available`; the name above exists on this Mac. XCTest checks photo gating, failed-request retention/retry, local readability, transport configuration, and Chinese controls at large text sizes. Deno tests use isolated fake providers for error/contract checks; they do not establish successful real AI extraction. Fixtures have hand-checked expectations in `fixtures/expected.json`. Compare real outputs with those facts when credentials are ready.

The project is checked in as a normal Xcode project. `python3 ios/generate_project.py` regenerates it after adding source/test files. `swift fixtures/generate.swift` regenerates the fictional JPEGs. Do not regenerate over manual signing changes without preserving them.

## Remaining slice-1 acceptance

- Real fixture photos through OpenRouter: both languages, amounts/dates/evidence, missing action/deadline, uncertainty and retry behavior.
- Physical iPhone capture/retake, readable full-resolution photo, English/Mandarin text-to-speech, Dynamic Type, tap targets and VoiceOver reading order.
- Learner's early hands-on review. Only then commit/tick slice 1 and continue to email-only accounts.

The approved order and all remaining work live in `devpost/checklist.md`.

## Interpretation refinement

Within medical and health-insurance scope, explanations adapt to the actual purpose of a statement, EOB, result, or enrollment notice. The screen shows purpose, actions/choices, and relevant timing. Facts have bilingual role labels and explanations; detailed values and source excerpts are expandable. Actions distinguish explicit instructions, options, and conditional steps, while effective/service dates stay separate from deadlines. No extracted steps uses conservative wording, not a blanket claim that no action is needed. Fixtures cover these cases; free-model output still requires checking against originals.
