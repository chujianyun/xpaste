# WPaste 应用图标

采用 `wpaste-app-icon-concept-v1.png` 中的彩色折纸 W：W 对应 WPaste，折叠纸带呼应复制、整理与粘贴内容。深蓝底色与青蓝、紫色和橙色纸带形成对比。

原始设计图保留透明圆角；应用图标位于 `WPaste/Resources/Assets.xcassets/AppIcon.appiconset`，包含 macOS 的 16、32、128、256、512 点各 1x / 2x 规格。通过 `sips -z` 从原图缩放生成，避免手工维护不同尺寸的设计。

`project.yml` 的 `ASSETCATALOG_COMPILER_APPICON_NAME` 指向 `AppIcon`。集成测试验证应用包声明了图标，且包含可读取的 256 像素 ICNS 兼容资源；更大尺寸由 Xcode 编译到 `Assets.car`。
