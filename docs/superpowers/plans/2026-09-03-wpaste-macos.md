# WPaste macOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the macOS 15+ WPaste menu-bar clipboard manager described by the approved design and reference screenshots.

**Architecture:** A Swift 6 SwiftUI application uses small service protocols around AppKit integration. SwiftData stores metadata and relationships, while an application-support file store owns image payloads and thumbnails. A central app model composes monitoring, filtering, search, pinboards, shortcuts, and overlay presentation without exposing system APIs directly to views.

**Tech Stack:** Swift 6, SwiftUI, AppKit, SwiftData, XCTest/Swift Testing, ServiceManagement, Carbon hot-key APIs, Accessibility APIs, LinkPresentation.

**Spec:** `docs/superpowers/specs/2026-09-03-wpaste-macos-design.md`

## Global Constraints

- Deployment target is macOS 15.0; primary architecture is Apple Silicon.
- UI is SwiftUI-first; AppKit is limited to windows, pasteboard, focus, keyboard simulation, and other system integration.
- The first release has no accounts, iCloud, AI, subscriptions, purchases, or telemetry.
- Rejected clipboard content and rejected previews must never be persisted.
- Default retention is exactly 7 days.
- Missing accessibility permission must degrade automatic paste to copy-only.
- The four screenshots in `protetype/` are the visual acceptance reference; unsupported sidebar entries shown there must not appear.

---

### Task 1: Buildable application skeleton and shared domain model

**Files:**
- Create: `WPaste.xcodeproj/project.pbxproj`
- Create: `WPaste/App/WPasteApp.swift`
- Create: `WPaste/App/AppModel.swift`
- Create: `WPaste/Domain/ClipboardItem.swift`
- Create: `WPaste/Domain/AppSettings.swift`
- Create: `WPasteTests/Domain/ClipboardItemTests.swift`
- Create: `.gitignore`

**Interfaces:**
- Produces: `ClipboardPayload`, `ClipboardItem`, `ClipboardSource`, `AppSettings`, and `@MainActor AppModel`.

- [ ] **Step 1: Write failing domain tests** for value equality, item-kind labels, a 7-day default retention, and copy-only fallback defaults.
- [ ] **Step 2: Run tests to verify the target or types do not exist:** `xcodebuild test -project WPaste.xcodeproj -scheme WPaste -destination 'platform=macOS' -only-testing:WPasteTests/ClipboardItemTests`.
- [ ] **Step 3: Create the Xcode project and minimal types.** Use a macOS application target with `MACOSX_DEPLOYMENT_TARGET = 15.0`, `SWIFT_VERSION = 6.0`, no external dependencies, and a test target. Model payloads as `text(String)`, `url(URL)`, `image(ImageMetadata)`, and `files([FileReference])`; keep platform objects out of the domain layer.
- [ ] **Step 4: Add the menu-bar scene and settings scene.** `WPasteApp` owns one `@State AppModel`, exposes Settings and Quit commands, and uses accessory activation policy so no Dock icon appears.
- [ ] **Step 5: Run the tests and a Debug build:** `xcodebuild test -project WPaste.xcodeproj -scheme WPaste -destination 'platform=macOS'` and `xcodebuild build -project WPaste.xcodeproj -scheme WPaste -configuration Debug`.
- [ ] **Step 6: Commit:** `git add .gitignore WPaste.xcodeproj WPaste WPasteTests && git commit -m 'feat: scaffold WPaste macOS app'`.

### Task 2: Pasteboard parsing, fingerprinting, and privacy filtering

**Files:**
- Create: `WPaste/Clipboard/PasteboardSnapshot.swift`
- Create: `WPaste/Clipboard/ClipboardParser.swift`
- Create: `WPaste/Clipboard/ContentFingerprint.swift`
- Create: `WPaste/Clipboard/PrivacyFilter.swift`
- Create: `WPasteTests/Clipboard/ClipboardParserTests.swift`
- Create: `WPasteTests/Clipboard/PrivacyFilterTests.swift`

**Interfaces:**
- Consumes: `ClipboardPayload`, `ClipboardSource`, `AppSettings`.
- Produces: `ClipboardParsing.parse(_:) -> ParsedClipboard?`, `ContentFingerprint.make(for:) -> String`, and `PrivacyFiltering.decision(for:settings:) -> PrivacyDecision`.

- [ ] **Step 1: Add failing fixtures and tests** proving parser priority is files, image, URL, text; multi-file copies remain one item; identical semantic content has an identical SHA-256 fingerprint; ignored bundle IDs, password managers, concealed types, transient types, and paused recording are rejected.
- [ ] **Step 2: Run:** `xcodebuild test -project WPaste.xcodeproj -scheme WPaste -destination 'platform=macOS' -only-testing:WPasteTests/ClipboardParserTests -only-testing:WPasteTests/PrivacyFilterTests`; expect compile/test failure.
- [ ] **Step 3: Implement immutable pasteboard snapshots** so tests do not touch the system pasteboard. Normalize URLs, text line endings, image bytes, and ordered file URLs before hashing.
- [ ] **Step 4: Implement privacy decisions before any persistence API is called.** Return only `.allow` or `.reject(reason)`; never attach raw payload data to rejection logs.
- [ ] **Step 5: Run the focused tests, then all tests.**
- [ ] **Step 6: Commit:** `git add WPaste/Clipboard WPasteTests/Clipboard && git commit -m 'feat: parse and filter clipboard content'`.

### Task 3: SwiftData history, image files, deduplication, and retention

**Files:**
- Create: `WPaste/Persistence/Models.swift`
- Create: `WPaste/Persistence/HistoryRepository.swift`
- Create: `WPaste/Persistence/ImageFileStore.swift`
- Create: `WPaste/Persistence/RetentionCleaner.swift`
- Create: `WPasteTests/Persistence/HistoryRepositoryTests.swift`
- Create: `WPasteTests/Persistence/ImageFileStoreTests.swift`

**Interfaces:**
- Produces: `HistoryRepositoryProtocol` with `upsert`, `search`, `delete`, `clear`, and `cleanExpired`; `ImageFileStoreProtocol` with `save`, `load`, and `delete`.

- [ ] **Step 1: Write failing in-memory SwiftData tests** for newest-first order, fingerprint deduplication, multi-pinboard membership, pinboard deletion semantics, all retention options, missing files, and corrupt image metadata.
- [ ] **Step 2: Run focused persistence tests and confirm failure.**
- [ ] **Step 3: Implement SwiftData models** for item, pinboard, membership, and settings. Store image paths relative to Application Support; do not copy source files.
- [ ] **Step 4: Implement transactional upsert and cleanup.** A duplicate updates timestamp/source metadata and moves to the front. Deletion removes owned image assets after the model transaction succeeds.
- [ ] **Step 5: Run focused tests and the full suite.**
- [ ] **Step 6: Commit:** `git add WPaste/Persistence WPasteTests/Persistence && git commit -m 'feat: persist clipboard history'`.

### Task 4: Clipboard monitoring and self-write suppression

**Files:**
- Create: `WPaste/Clipboard/ClipboardMonitor.swift`
- Create: `WPaste/Clipboard/PasteboardClient.swift`
- Create: `WPasteTests/Clipboard/ClipboardMonitorTests.swift`

**Interfaces:**
- Consumes: parser, privacy filter, history repository.
- Produces: `ClipboardMonitoring.start()`, `stop()`, and `suppressNextWrite(fingerprint:until:)`.

- [ ] **Step 1: Write failing tests** using a fake `changeCount` clock for one capture per change, pause behavior, privacy-before-storage ordering, restart behavior, and suppression of app-originated writes.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Implement an actor-backed polling loop** with cancellation-safe start/stop and injectable clock. Snapshot `NSPasteboard.general` only after `changeCount` changes.
- [ ] **Step 4: Wire the monitor into `AppModel` lifecycle and menu-bar pause state.**
- [ ] **Step 5: Run focused and full tests.**
- [ ] **Step 6: Commit:** `git add WPaste/Clipboard WPaste/App WPasteTests/Clipboard && git commit -m 'feat: monitor the system clipboard'`.

### Task 5: Search and pinboard behavior

**Files:**
- Create: `WPaste/Features/History/HistoryStore.swift`
- Create: `WPaste/Features/Pinboards/PinboardStore.swift`
- Create: `WPasteTests/Features/HistoryStoreTests.swift`
- Create: `WPasteTests/Features/PinboardStoreTests.swift`

**Interfaces:**
- Produces: observable stores with explicit commands for search and create/rename/reorder/delete pinboard.

- [ ] **Step 1: Write failing tests** for case/diacritic-insensitive search over text, URL, filename, and source app; multi-board favorites; and stable ordering.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Implement stores as `@MainActor @Observable` adapters** over the repository; views must not access SwiftData directly.
- [ ] **Step 4: Run focused and full tests.**
- [ ] **Step 5: Commit:** `git add WPaste/Features WPasteTests/Features && git commit -m 'feat: add search and pinboards'`.

### Task 6: Paste coordination and accessibility fallback

**Files:**
- Create: `WPaste/Paste/PasteCoordinator.swift`
- Create: `WPaste/Paste/AccessibilityClient.swift`
- Create: `WPaste/Paste/FrontmostApplicationClient.swift`
- Create: `WPasteTests/Paste/PasteCoordinatorTests.swift`

**Interfaces:**
- Produces: `PasteCoordinating.paste(item:mode:target:) async -> PasteResult`, where result is `.pasted`, `.copiedOnly(PasteFallbackReason)`, or `.unavailable`.

- [ ] **Step 1: Write failing tests** for target capture, payload write, plain-text conversion, window-close/focus/paste ordering, exited target, denied accessibility, and failed key event.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Implement pasteboard writers for all four payloads**, an injectable accessibility client, and non-blocking fallback results. Mark the outgoing fingerprint for monitor suppression before writing.
- [ ] **Step 4: Run focused and full tests.**
- [ ] **Step 5: Commit:** `git add WPaste/Paste WPasteTests/Paste && git commit -m 'feat: coordinate paste with safe fallback'`.

### Task 7: Global shortcuts and overlay window

**Files:**
- Create: `WPaste/Shortcuts/Shortcut.swift`
- Create: `WPaste/Shortcuts/ShortcutManager.swift`
- Create: `WPaste/Overlay/OverlayWindowController.swift`
- Create: `WPasteTests/Shortcuts/ShortcutManagerTests.swift`
- Create: `WPasteTests/Overlay/OverlayPlacementTests.swift`

**Interfaces:**
- Produces: shortcut registration/update/reset with rollback on conflict, and overlay show/hide/placement APIs accepting the mouse screen and captured target application.

- [ ] **Step 1: Write failing tests** for defaults, internal conflicts, failed-registration rollback, numeric commands, mouse-screen selection, safe-area bottom placement, focus loss, and Escape dismissal.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Implement Carbon hot-key registration behind a protocol** and persist only successfully registered shortcuts.
- [ ] **Step 4: Implement a borderless AppKit panel** hosting SwiftUI, able to become key, span the visible frame, and remain above normal windows without stealing the remembered target.
- [ ] **Step 5: Run focused and full tests.**
- [ ] **Step 6: Commit:** `git add WPaste/Shortcuts WPaste/Overlay WPasteTests/Shortcuts WPasteTests/Overlay && git commit -m 'feat: add shortcuts and overlay window'`.

### Task 8: History cards, navigation, and context actions

**Files:**
- Create: `WPaste/Features/History/HistoryOverlayView.swift`
- Create: `WPaste/Features/History/ClipboardCardView.swift`
- Create: `WPaste/Features/History/CardContentViews.swift`
- Create: `WPaste/Features/History/OverlayNavigation.swift`
- Create: `WPasteUITests/OverlayUITests.swift`

**Interfaces:**
- Consumes: history and pinboard stores plus the paste coordinator.

- [ ] **Step 1: Add failing navigation unit tests and UI smoke tests** for search, arrow selection, Return, Escape, Command-1…9, context menu commands, board switching, and drag reorder.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Implement the horizontal overlay to match `protetype/Xnip2026-09-03_18-26-47.jpg`.** Use fixed-width adaptive cards, source accent color/icon, selected outline, horizontal scrolling, screen-sharing redaction, missing-file disabled state, and accessible labels.
- [ ] **Step 4: Run tests, then capture light/dark screenshots at 1x and 2x for comparison.**
- [ ] **Step 5: Commit:** `git add WPaste/Features WPasteUITests && git commit -m 'feat: build clipboard overlay interface'`.

### Task 9: Settings, login item, preview cache, and onboarding

**Files:**
- Create: `WPaste/Features/Settings/SettingsView.swift`
- Create: `WPaste/Features/Settings/GeneralSettingsView.swift`
- Create: `WPaste/Features/Settings/PrivacySettingsView.swift`
- Create: `WPaste/Features/Settings/ShortcutSettingsView.swift`
- Create: `WPaste/Features/Onboarding/OnboardingView.swift`
- Create: `WPaste/System/LoginItemClient.swift`
- Create: `WPaste/Preview/LinkPreviewService.swift`
- Create: `WPasteTests/Settings/SettingsTests.swift`

**Interfaces:**
- Produces: general/privacy/shortcut settings commands, login-item status changes, cancellable URL-preview fetch/cache, and first-run acknowledgement.

- [ ] **Step 1: Write failing tests** for retention mapping, clear history/cache, quit cleanup, ignored-app edits, login-item errors, preview-disabled behavior, preview failure fallback, and first-run state.
- [ ] **Step 2: Run focused tests and confirm failure.**
- [ ] **Step 3: Implement settings matching the three settings screenshots.** Omit AI, subscription, purchase, and iCloud entries; use the design specification as authority where screenshots contain unsupported items.
- [ ] **Step 4: Implement ServiceManagement login items, LinkPresentation previews, and just-in-time accessibility guidance.** Never fetch a preview when privacy settings disable it or filtering rejects the item.
- [ ] **Step 5: Run focused and full tests; manually verify VoiceOver labels and keyboard traversal.**
- [ ] **Step 6: Commit:** `git add WPaste/Features/Settings WPaste/Features/Onboarding WPaste/System WPaste/Preview WPasteTests/Settings && git commit -m 'feat: add settings privacy and onboarding'`.

### Task 10: Packaging, recovery paths, and release acceptance

**Files:**
- Create: `Config/Debug.xcconfig`
- Create: `Config/Release.xcconfig`
- Create: `Scripts/package-dmg.sh`
- Create: `docs/release-checklist.md`
- Create: `WPasteTests/Integration/ClipboardLifecycleTests.swift`

**Interfaces:**
- Consumes: the complete application.
- Produces: unsigned local `.app`/DMG packaging plus documented Developer ID signing and notarization inputs.

- [ ] **Step 1: Add integration tests** for capture-to-persistence-to-writeback, image lifecycle, missing source files, corrupt record isolation, and schema migration startup.
- [ ] **Step 2: Run integration tests and fix only defects required by the approved specification.**
- [ ] **Step 3: Add release configuration placeholders as environment-fed build settings** (`DEVELOPMENT_TEAM`, signing identity, notarization profile) and a script that refuses to package a failed Release build.
- [ ] **Step 4: Run:** `xcodebuild test -project WPaste.xcodeproj -scheme WPaste -destination 'platform=macOS'` and `xcodebuild archive -project WPaste.xcodeproj -scheme WPaste -archivePath build/WPaste.xcarchive`.
- [ ] **Step 5: Perform the manual acceptance matrix** from design section 10.3 and record pass/fail results in `docs/release-checklist.md`; do not claim unsupported third-party app coverage without executing it.
- [ ] **Step 6: Commit:** `git add Config Scripts docs/release-checklist.md WPasteTests/Integration && git commit -m 'build: add WPaste release packaging'`.
