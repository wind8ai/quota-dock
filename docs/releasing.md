# 构建、签名与产物管理

## 发布输入

1. 在独立的 `codex-tools` 仓库中完成代码 review、测试和提交。只提交本项目及根仓配套文件。
2. 版本和 build number 只维护在 `Resources/Info.plist`；发布新修改时更新版本/build。本次 2.1/build 12 为原版工程化迁移，未新增产品功能。
3. 固定 macOS、Swift 与 SDK；使用 `DEVELOPER_DIR` 选择本机已安装的 Apple 工具链，记录其版本。无需下载第三方依赖。
4. 执行 `scripts/package.sh`。它会依次测试、release 构建、签名验证、使用 `ditto` 打包、生成 SHA-256 和构建记录。任一步失败都不视为可发布产物；`dist` 中可能有上次产物，须核对构建记录与校验和。

## 签名与分发

- 默认 ad-hoc 签名与旧应用一致，供本机验证；不能等同于 Developer ID 签名或公证通过。
- 有 Developer ID Application 证书时，通过 `SIGNING_IDENTITY` 指定证书名称或指纹；证书由本机 Keychain 管理，私钥和认证信息禁止提交。
- 对外分发按照 Apple [Developer ID](https://developer.apple.com/developer-id/) 和 [notarization 文档](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) 完成公证。当前本机旧工具链未配置 notarization，本轮不提交任何 Apple 公证请求。
- 公证需要支持 `notarytool` 的工具链。上传已签名 ZIP 并获得 accepted 结果后，将票据 staple 到 `.app`，验证票据，然后重新用 `ditto -c -k --sequesterRsrc --keepParent` 打包并更新 SHA-256。不要再次运行 `package.sh` 覆盖已 staple 的应用。
- ZIP 打包沿用 Apple [软件分发打包文档](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution) 的 `ditto --keepParent` 模式。

## 产物归属

- `build/`、`dist/`、`.build/`、`artifacts/` 和所有 `.app`/`.zip` 均被根 `.gitignore` 排除。Git 中不保存真实会话、额度缓存、用户截图、证书或旧二进制副本。
- `.zip`、`.sha256`、`.build-info.txt` 作为同一组保存在后续明确的 release 或制品存储，不把“本地打包成功”当成已经发布。
- 标签约定为 `quota-dock/v<version>`；签名或公证方式、目标架构、源码提交及验证范围必须写入发布说明。本仓尚无 remote，本轮不创建发布标签、不推送。
- 脚本按本机架构输出；只有另行在目标架构构建并验证后，才能声明支持对应架构的发布包。不同工具链、路径、签名与压缩元数据可导致哈希不同。

## 技术选择

采用 Apple 工具链的 `swiftc` 编译和 Swift 原生 `precondition` 断言，以无优化模式执行测试。当前机器的 Swift 5.3 Command Line Tools 缺少 `xctest`，其 SwiftPM 构建也要求该工具，因此本项目不引入 SwiftPM/XCTest 依赖，也不保留双套构建路径。QuotaCore 是项目内部源码目录，不是独立发布的库；AppKit 入口与核心分离，用合成数据覆盖解析、周期与缓存规则。
