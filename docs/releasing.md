# 构建、签名与发布

**中文** | [English](releasing.en.md)

## 构建输入

版本和 build number 只在 `Resources/Info.plist` 维护。发布前提交本项目改动，并记录 macOS、Swift、SDK 和目标架构。需要选择已安装的工具链时，通过 `DEVELOPER_DIR` 指定。

```sh
./scripts/package.sh
```

脚本依次运行测试、release 构建、签名校验和 `ditto` 打包，输出到 `dist/`：

- `QuotaDock-<version>-<build>-<arch>.zip`
- 对应 `.sha256`
- 对应 `.build-info.txt`，记录源码提交、工作区状态、工具链和签名身份

构建只针对本机架构，不生成 universal binary。ZIP、校验和、构建记录作为一组制品保留。脚本可重复运行，但不同 SDK、签名时间戳和压缩元数据可能产生不同哈希。

## 签名

默认使用 ad-hoc 签名供本机验证，不等同于 Developer ID 签名或 Apple 公证。

已有 Developer ID Application 证书时：

```sh
SIGNING_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' ./scripts/package.sh
```

证书模式启用 hardened runtime 和安全时间戳。证书及私钥由本机 Keychain 管理，不进入 Git。

对外发布二进制时，按 Apple [Developer ID](https://developer.apple.com/developer-id/) 和 [notarization 文档](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) 完成公证。当前仓库没有已公证的二进制发布。

公证 accepted 后，将票据 staple 到 `.app` 并验证，再重新用 `ditto -c -k --sequesterRsrc --keepParent` 打包和更新校验和。不要用 `package.sh` 覆盖已经 staple 的应用。

## 仓库与制品

公开源码位于 [wind8ai/quota-dock](https://github.com/wind8ai/quota-dock)。独立仓库标签使用 `v<version>`；维护 monorepo 的标签使用 `quota-dock/v<version>`。源码推送、版本标签和二进制发布是独立步骤，推送源码不表示对应二进制已发布。

Git 保存源码、测试、脚本和文档展示素材。构建缓存、应用包、ZIP、真实会话、额度缓存和实际额度运行截图均被忽略。文档状态图使用合成额度，截图区域只包含液体槽和示例头像。

## 技术选择

使用 Apple 工具链的 `swiftc` 和 Swift 原生断言执行测试，不需要 SwiftPM 或 XCTest runtime。测试以 `-Onone` 编译，断言失败返回非零退出码。核心数据及几何规则位于 `Sources/QuotaCore/`，AppKit 窗口和绘制位于 `Sources/QuotaDock/`。
