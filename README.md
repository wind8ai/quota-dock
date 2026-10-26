# QuotaDock

**中文** | [English](README.en.md)

在 macOS 的 Codex 头像上方显示剩余额度。液面表示比例，数字显示百分比，窗口移动时跟随，不挡鼠标点击。

当前版本 3.1.1 / build 24。

![QuotaDock 六种额度状态](https://raw.githubusercontent.com/wind8ai/quota-dock/main/docs/images/quota-dock.gif?v=f2ce9a4e8a5e)

图中额度为模拟值。[查看静态图](docs/images/quota-dock-states.png)

青蓝色表示剩余至少 50%，琥珀色表示 20% 到不足 50%，红色表示不足 20%。`0` 表示耗尽，`--` 表示暂时读不到有效额度。

## 构建与运行

需要 macOS 11+、Swift 5.3+，以及已用 ChatGPT 登录的 Codex CLI。已在 Apple Silicon 上验证。没有开发工具时，先运行 `xcode-select --install`。

```sh
git clone https://github.com/wind8ai/quota-dock.git
cd quota-dock
./scripts/build.sh
./scripts/sign.sh
open build/QuotaDock.app
```

默认使用 ad-hoc 签名，尚未经过 Apple 公证。应用没有 Dock 图标，也不自动添加登录项。退出时在活动监视器中结束 QuotaDock，或运行 `pkill -x QuotaDock`。

## 额度怎么算

通过本机 Codex CLI 的 `account/rateLimits/read` 查询服务端。优先显示 5 小时额度，没有时显示每周额度，不计入 Spark、credits 或 reserve。

主窗口可见时约每 5–6 秒查询一次，隐藏时约每 30 秒查询。接口响应还需要时间，因此不会与原生推送同时变化。查询失败会逐步延长重试间隔，最长 60 秒，不并发请求。

剩余额度按 `100 - usedPercent` 计算，四舍五入显示。读取失败、数据超过一分钟或到达重置时间时显示 `--`，不使用旧会话日志或跨重启缓存。

CLI 和桌面应用可能登录了不同账号。与原生圆环对照时，请确认账号和周期一致。工具不直接读取令牌，也不发起模型任务。

## 排查问题

检查窗口位置：

```sh
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose
```

检查账户额度，需要登录和网络：

```sh
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose-quota
```

## 开发

运行核心测试和原生面板测试：

```sh
./scripts/test.sh
bash scripts/test-app.sh
```

生成中英文效果图，需要 FFmpeg：

```sh
./scripts/render-states.sh --animate
./scripts/render-states.sh --english --animate
```

`./scripts/preview-animation.sh` 打开交互预览。`./scripts/package.sh` 执行测试、构建、签名和打包。构建产物与运行数据不提交到 Git。

## 更多说明

- [定位、数据来源和限制](docs/behavior.md)
- [原生用量圆环的实现参考](docs/native-usage-reference.md)
- [用量条消失问题复盘](docs/visibility-review.md)
- [签名与发布](docs/releasing.md)
- [更新记录](CHANGELOG.md)
- [复刻提示词](docs/recreate-prompt.md)
