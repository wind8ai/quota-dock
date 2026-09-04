# 2.1 工程化迁移记录

日期：2026-09-04。工程根目录：`/Users/ben/Workspace/codex-tools`。

## 仓库边界

开始时目录为空，Git 向上识别到 `/Users/ben/Workspace`。本次在 `codex-tools/.git` 初始化独立仓库，分支为 `main`，未配置 remote。`projects/quota-dock` 不设子仓，不使用 submodule；从该目录查询 Git 根目录仍为 `codex-tools`。

父仓已有的 `.gitmodules` 修改、已暂存的 `todo` 和 `week-reports` 删除全部保留。通过父仓索引 SHA-256、`git status --porcelain=v1` 和 `git diff --binary HEAD` 与迁移前基线比较，确认一致。父仓现有 `.gitignore` 的 `/*` 已忽略本目录，未写入父仓任何配置。未操作 `tmo-skill-knowledge`。

## 源码归档方式

旧源码：`/Users/ben/Documents/Codex/2026-07-17/c/work/CodexQuotaBadge/`。

- `Main.swift` 拆为 `Sources/QuotaDock/main.swift` 和 `Sources/QuotaCore/*.swift`；合并回读对比后，除文件级可见性调整、测试用目录参数和定位常量提取外，保留原实现。
- `Info.plist` 放入 `Resources/`。显示名称、应用名称和 executable 改为 `QuotaDock`；版本 2.1、build 12、最低 macOS 11.0、bundle identifier 均保留。
- README 已按账号栏展示重写，纠正旧文件中的宠物描述。新目录中的源码、测试、脚本和文档是后续维护入口。
- `quota-history-v2` 编码结构和 `com.ben.codex-quota-badge` 持久化域保持不变。旧数据直接复用，无永久双读 fallback。

## 已完成的验证

- 19 个原生 Swift 断言用例通过：主额度/Spark 过滤、嵌套回执、异常行、最新周期、120 秒边界、百分比钳制、无数据、文件修改时间回退、12 文件限制、2 MB 尾读、缓存恢复及边界、5 条历史上限、96/8 位置偏移。
- `scripts/package.sh` 完整通过：测试、release 编译、组装应用、ad-hoc 签名验证和 ZIP 打包。
- 解压 ZIP 后重新执行 `codesign --verify --strict` 通过，解压后的 executable 和 Info.plist 与构建应用逐字节一致。
- 本机为 arm64，工具链为 Apple Swift 5.3.2 / macOS SDK 11.1。本机没有 `xctest`；最终脚本直接使用 `swiftc`，测试通过 `-Onone` 保持断言有效。
- 新 `.app` 直接启动后持续运行 3 秒，无 stderr 输出；随后仅结束本次启动的新进程。窗口探针未发现新旧徽标的成对可见窗口，故本轮未重新确认实际 UI 对齐、遮挡或跨屏表现，已确认的 96/8 数值通过代码及回归用例保留。
- 旧进程 PID 506 在验证后仍指向旧产物路径，未切换其运行入口。旧源码与产物的文件哈希复核一致。
- 构建产物、ZIP、测试缓存及本机 smoke 记录均被忽略，不进入本次提交。

测试注册入口为 `Tests/QuotaCoreTests/main.swift`；新增测试方法时在该入口的用例数组中登记。所有回执为合成数据，UserDefaults 用例使用随机测试域并清理。

## 运行与回退边界

旧运行路径：`/Users/ben/Documents/Codex/2026-07-17/c/outputs/CodexQuotaBadge.app/Contents/MacOS/CodexQuotaBadge`。

本次没有移动、覆盖或删除旧源码、旧 `.app`、旧 `.zip`，没有添加登录项或改写启动路径。后续正式切换按 README 操作：结束旧实例后启动新应用，检查实际账号栏对齐；如有问题，退出新实例再启动保留的旧 `.app`。确认新入口和手工登录项已完成切换前，不清理旧目录。

产物仅在本地生成；未进行 Developer ID 实测、Apple notarization、远端上传或推送。详见 [发布规则](releasing.md)。

## 旧文件 SHA-256 基线

下列哈希在迁移前记录，并在迁移验证后复核一致：

| 原文件 | SHA-256 |
| --- | --- |
| `work/CodexQuotaBadge/README.md` | `e965d97185154095bc1d5f58dcb0f4c2dbf0f4484c6007c91280c2cf3e86b6a4` |
| `work/CodexQuotaBadge/Main.swift` | `57533f97ed534db84cfcb87797379794984f784d4fba66c88156d3f53fc36f3b` |
| `work/CodexQuotaBadge/Info.plist` | `4227df9f57b312194c2a9813118acf43a23bd4ac70d6a7baf4f1b0f9369139b7` |
| `outputs/CodexQuotaBadge.app/Contents/Info.plist` | `4227df9f57b312194c2a9813118acf43a23bd4ac70d6a7baf4f1b0f9369139b7` |
| `outputs/CodexQuotaBadge.app/Contents/_CodeSignature/CodeResources` | `6686de10a28a2fe11b36cbb86dcbacc827cfc4ea116b4dabf1845e5aee629e9b` |
| `outputs/CodexQuotaBadge.app/Contents/MacOS/CodexQuotaBadge` | `3287c4d472ee0eb6073d13b9507b72e0bb551bd428f406db83eeedd25bca1058` |
| `outputs/CodexQuotaBadge.zip` | `32fba2e356602221b72c36ef5c57b481e530ae3f3477b4008198508ad5897483` |
