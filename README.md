# QuotaDock

**中文** | [English](README.en.md)

把 Codex 的剩余额度放在头像上方的 macOS 液体槽。液面表示剩余比例，底部显示整数；窗口移动时跟随，鼠标可以穿透。

![QuotaDock 六种模拟额度状态](https://raw.githubusercontent.com/wind8ai/quota-dock/main/docs/images/quota-dock.gif?v=23e7d7dd89be)

当前版本 **3.1.1 / build 24**。青蓝色表示剩余至少 50%，琥珀色表示 20% 到不足 50%，红色表示不足 20%。`0` 保留红色细线，`--` 表示当前没有有效的服务端快照。图中六种额度均为模拟值；下方圆环按同列额度同步绘制，中心图标和头像保留用户提供的截图。无数据圆环使用虚线示意。

当前样式为 36 × 104 pt 液体槽、最多 15 pt 白色等宽重体与 4 pt 扩散黑色阴影，不使用数字底板或描边。按当前账号栏布局，与原生圆环留出约 20 pt 间隔。[查看静态效果图](docs/images/quota-dock-states.png)。PNG 与 GIF 的上方槽体直接使用当前生产视图绘制，数值为合成数据；下方侧栏与头像使用用户授权保留的截图。

## 构建与启动

需要 macOS 11 或更新版本，以及 Apple Command Line Tools 或 Xcode、Swift 5.3 或更新版本。Swift 代码无需第三方库；运行时需要已用 ChatGPT 登录的兼容 Codex CLI。目前已在 Apple Silicon 上构建和验证。

```sh
xcode-select --install  # 已安装开发工具时跳过

git clone https://github.com/wind8ai/quota-dock.git
cd quota-dock
./scripts/build.sh
./scripts/sign.sh
open build/QuotaDock.app
```

应用不出现在 Dock 中，也不会自动添加登录项。退出时在活动监视器中结束 `QuotaDock`，或执行：

```sh
pkill -x QuotaDock
```

## 它读取什么

通过本机 Codex CLI 的官方 app-server 协议读取账户额度：主窗口可见时每 5 秒、隐藏时每 30 秒查询；失败逐步退避至 60 秒，不重叠请求。优先显示 5 小时窗口，没有时显示每周窗口；只使用 codex 桶，不使用 Spark、credits 或 reserve。

剩余额度按 `100 - usedPercent` 计算，显示四舍五入整数。服务端新值可升可降。读取失败、快照超过一分钟或已到重置时间时显示 `--`，不再扫描会话日志或使用旧跨重启额度缓存。每次查询都有超时，并清理自己的子进程。

运行时需要可用的 Codex CLI 和 ChatGPT 登录。自动查找 PATH、常用 CLI 安装位置及已安装 Codex/ChatGPT 应用内的 CLI。不读取令牌，不发起模型任务，不修改桌面应用；桌面选中的账号与 CLI 登录账号可能不同，比较原生圆环时须核对账号与周期。

液面有两层波动和上浮气泡，额度变化约 0.6 秒过渡。目标窗口隐藏时暂停动画；开启 macOS 的“减少动态效果”时保持静止。

## 开发

```sh
./scripts/test.sh                  # 29 个核心／离线协议回归用例
bash scripts/test-app.sh           # 原生面板连续重建 20 次，验证额度与动画保留
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose  # 只读窗口诊断
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose-quota  # 读取真实账户额度（需要登录和网络）
./scripts/preview-animation.sh     # 合成额度交互预览，关闭窗口退出
./scripts/render-states.sh --animate  # 重新生成中文静态图与 GIF，需要 FFmpeg
./scripts/package.sh               # 测试、构建、签名、ZIP、校验和
```

`build/`、`dist/`、`.build/` 和运行数据不进入 Git。默认签名为 ad-hoc，尚未完成 Apple 公证。

- [定位、数据来源和已知限制](docs/behavior.md)
- [原生用量圆环的实现参考与差异](docs/native-usage-reference.md)
- [用量条消失问题复盘与验证边界](docs/visibility-review.md)
- [构建、签名和发布](docs/releasing.md)
- [更新记录](CHANGELOG.md)
- [用 Codex 复刻的提示词](docs/recreate-prompt.md)

执行 `./scripts/render-states.sh --english --animate` 可生成英文标签的预览。
