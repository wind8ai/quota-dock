---
status: done
goal: 用官方 Codex app-server 账户额度读取替代会话日志估计，移除会阻止服务端修正的缓存逻辑。
---

# Plan 002: 服务端额度快照

## 背景
原生圆环消费账户服务端快照，轮询或推送并校验身份与新旧时间。当前 QuotaDock 扫描 JSONL 且同周期只降不升，会滞后并拒绝合法额度修正。本机已通过初始化与 account/rateLimits/read 读取到 codex 每周额度，无需读取令牌。

## 参考资料
- https://learn.chatgpt.com/docs/app-server — initialize、account/read、account/rateLimits/read。
- `docs/native-usage-reference.md` — 本机原生圆环来源与显示语义。
- `Sources/QuotaCore/QuotaReader.swift`、`QuotaStabilizer.swift` — 将删除的旧数据路径。

## 决策
- 使用独立、短生命周期 stdio app-server 子进程，每 30 秒读取；超时终止自己的子进程。不新建模型任务、不读取令牌、不调用私有 HTTP 接口。
- 读取前后 account/read 对比登录身份，仅在一致时发布快照；不输出或持久化邮箱。
- 优先多桶 codex 数据，按窗口时长选 5 小时，否则每周。不误用 Spark，不混合两个周期。
- 服务端最新值允许上升或下降。失败或过期显示未知，不读旧 JSONL，也不恢复旧跨重启额度缓存。
- 已有单根视觉样式、窗口跟随与面板恢复不变。增加只读额度诊断，标明周期与来源。
- 登录身份以本机 CLI 为准；不能自动确认桌面多账号选中身份，明确记录该限制。

## 范围
包含解析、子进程协议、超时、身份保护、失败显示、集成、回归测试及文档迁移。
不包含私有推送接口、API key、登录或切换账号、消费额度重置、后台服务或安装依赖。

## 步骤
- [x] 只读追踪原生数据刷新，验证官方额度接口在本机可用。
- [x] 逐步测试并实现 codex 桶和周期解析。
- [x] 测试并实现受控 JSON-RPC 子进程、身份核对和超时清理。
- [x] 接入界面，删除无依赖的旧日志及单调缓存实现和相应测试。
- [x] 验证、更新文档与版本，完成最终 diff 审阅；不推送。

## 验证
- `./scripts/test.sh` → 核心测试与离线协议 fixture 测试通过，不依赖真实登录或网络。
- `bash scripts/test-app.sh` → 面板重建继续保留数值及动画。
- `./scripts/build.sh && ./scripts/sign.sh` → 构建与签名通过。
- `build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose-quota` → 报告官方来源、周期、剩余值或明确错误，不泄露身份与令牌。
- `git diff --check` → 无空白错误。

## 待决问题
- 无

## 下一步
实现完成。后续使用中如出现未知值，先运行 --diagnose-quota 核对 CLI 登录、网络和周期；不要恢复旧日志备用路径。多账号桌面／CLI 身份一致性仍需用户核对。

## 验证结果
- 解析、协议读取和有效期各自先出现预期失败测试，再通过；最终 25 个核心／离线协议测试通过。
- 原生面板连续替换 20 次测试通过；最终构建、签名、diff check 通过。
- 官方 CLI `0.164.0-alpha.11.1` 本机真实读取成功，识别每周窗口；诊断不输出邮箱、令牌或 credits 余额。
- 3.1.0 启动后，用户于 2026-10-26 确认本工具与原生圆环的每周读数一致。
- 本轮未实测真实账号切换或网络中断；离线 fixture 覆盖身份变化、无登录、异常协议、进程退出和超时。未承诺原生推送时效或多账号自动匹配。
