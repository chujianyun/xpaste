# WPaste 0.1 Release Checklist

## Automated checks

- [x] Regenerate `WPaste.xcodeproj` from `project.yml`.
- [x] Run the complete macOS unit and integration test suite.
- [x] Archive a Release build with the macOS 15 deployment target.
- [x] Create and checksum-verify `build/WPaste.dmg`; inspect the archived app bundle metadata and binary architectures.
- [ ] Verify Developer ID signature when signing credentials are configured.
- [ ] Submit and staple notarization when Apple credentials are configured.

## Manual acceptance matrix

- [ ] Copy and paste text, URL, image, one file, and multiple files in Safari, Chrome, Finder, WeChat, WPS/Office, and Xcode.
- [ ] Verify deduplication and newest-first ordering.
- [ ] Verify search by text, URL, filename, and source application.
- [ ] Verify one item can belong to multiple Pinboards and deleting a Pinboard retains history.
- [ ] Verify single- and multi-display placement, full-screen apps, Spaces, light/dark appearance, and scaled displays.
- [ ] Verify missing accessibility permission degrades to copy-only.
- [ ] Verify missing source files remain visible and cannot be pasted.
- [ ] Verify pause, ignored applications, confidential/transient clipboard types, and quit cleanup.
- [ ] Verify screen-sharing redaction and link-preview opt-out.
