# Draft reply to App Review

Paste into the App Store Connect message thread for submission
`6e72be71-5aa7-436c-9187-ad38e527b376`, with build 1.1.1 (2) attached.

Review before sending: it states things that must be true at the moment you send it — the
support page has to be live, and the Support URL field has to already point at it.

---

Hello,

Thank you for the detailed review of Prompter Glass 1.1.0. All three issues are addressed in
build 1.1.1 (2).

**Guideline 1.5 — Support URL.** The URL we submitted pointed at the project's GitHub issue
tracker, which we now understand does not serve as a support page: it requires a GitHub account
and offers no direct way to contact us. We have published a dedicated support page and updated
the Support URL in App Store Connect to:

https://victorcastro.github.io/prompter-glass/support.html

It gives a contact email that needs no account of any kind, a stated response time, instructions
for reporting a problem, the system requirements, and answers to the questions users are most
likely to ask about the microphone and voice tracking features.

**Guideline 2.4.5(i) — temporary entitlement exception.** We have removed
`com.apple.security.temporary-exception.mach-lookup.global-name` from the app. Build 1.1.1 (2)
ships with only `com.apple.security.app-sandbox` and `com.apple.security.device.audio-input`.

We verified on a signed, sandboxed Release build that voice tracking still works with the
exception removed: audio capture, on-device transcription with SpeechAnalyzer, and the reading
highlight all function normally. Reviewing the sandbox log during that run, the app never
attempts the `com.apple.audioanalyticsd` lookup at all, so the exception was unnecessary. We have
also added a check to our continuous integration that fails the build if any temporary exception
entitlement is reintroduced.

**Guideline 2.1(a) — the Voice tracking toggle was unresponsive.** Thank you for this report; we
reproduced it. The toggle was disabled whenever no script with text was selected — which is the
state of the app immediately after installation, with an empty script library — and nothing on
screen explained why. It looked broken because, for a new user, it effectively was.

In 1.1.1 the toggle is always interactive, and any state that is not listening now says what is
missing and offers the action that resolves it:

- With no script selected, it says a script must be picked and offers a button that opens the
  script library.
- While macOS installs the on-device speech model for the current language, it shows a labeled
  progress row naming the download, instead of an unlabeled spinner.
- If the microphone permission is denied, it links to System Settings.
- If activation fails, it now distinguishes the cause — an unavailable speech model, an audio
  input failure, an unsupported language — instead of reporting every failure as a language
  problem, and offers a Retry button.

Activation is also bounded by a timeout, so it can no longer stay in a progress state
indefinitely.

Additionally, the app now creates one sample script on first launch when the library is empty, so
voice tracking, the floating overlay and scroll playback are all usable immediately after
installation. The sample script can be edited or deleted like any other.

We tested this on a clean installation, resetting the microphone permission with `tccutil` first,
and confirmed that clicking the Voice tracking toggle as the very first action after launch
always produces a visible, explanatory response.

Please let us know if anything else needs attention.

Best regards,
Victor Castro
