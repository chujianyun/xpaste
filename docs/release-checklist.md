# WPaste 0.1 Release Checklist

2026-09-05：0.1.0 完整测试通过（51 项测试，含参数化用例共 53 次执行；0 失败、0 跳过）。通用版及 arm64 / x86_64 Release archive 已生成，三个 DMG 均校验通过。本次通用 archive 已安装到 `/Applications/WPaste.app` 并在 Apple 芯片 Mac 上启动。Intel 实机运行、Developer ID 分发签名、公证及下列手工验收仍待完成。详见 [0.1.0 发布说明](releases/v0.1.0.md)。

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
