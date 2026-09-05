# 固定签名身份

Debug、Release 和测试目标使用同一张 Apple Development 证书。证书指纹固定在 `project.yml`，打包脚本和签名集成测试会验证产物使用该证书，缺少证书或签名不匹配时停止打包，不回退到未签名构建。

- SHA-1 指纹：`DC86852A3142B093C0D6EF89F9978BC63349E0AF`
- Team Identifier：`7PXD675DGC`
- 应用 Bundle Identifier：`com.chujianyun.wpaste`

构建机器必须在钥匙串中安装对应证书及私钥。本仓库不保存私钥。续期或更换证书时，应同步更新配置、打包检查和测试，并检查新旧版本的 designated requirement 是否兼容。

从未签名版本切换到固定签名版本后，macOS 可能要求重新授予辅助功能权限。授权必须由用户在系统设置中完成；应用每次粘贴实时查询系统授权状态。若系统仍保留旧条目，退出 WPaste，在辅助功能列表删除旧条目并重新添加 `/Applications/WPaste.app`，再启动应用。

此证书用于本机开发签名，不等同于 Developer ID 分发签名或公证。
