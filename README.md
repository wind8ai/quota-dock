# QuotaDock

**中文** | [English](README.en.md)

把 Codex 的剩余额度放在头像上方的 macOS 液体槽。液面表示剩余比例，底部显示整数；窗口移动时跟随，鼠标可以穿透。

![QuotaDock 六种模拟额度状态](https://raw.githubusercontent.com/wind8ai/quota-dock/main/docs/images/quota-dock.gif?v=74db1e89de0b)

当前版本 **3.0.3 / build 16**。绿色表示剩余至少 50%，琥珀色表示 20% 到不足 50%，红色表示不足 20%。`0` 保留红色细线，`--` 表示没有数据或缓存。图中六种额度均为模拟值。

## 构建与启动

需要 macOS 11 或更新版本，以及 Apple Command Line Tools 或 Xcode、Swift 5.3 或更新版本。应用没有第三方依赖，目前已在 Apple Silicon 上构建和验证。

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

每 30 秒从本机 `~/.codex/sessions` 的 `token_count` 回执读取 `limit_id=codex` 的主额度，过滤 Spark 独立额度。不会请求额度服务，也不修改 ChatGPT/Codex 应用包。

剩余额度按 `100 - used_percent` 计算，显示为四舍五入后的整数。缓存跨重启保留，暂时读不到回执时沿用缓存。显示可能滞后于实际使用量，账号切换没有独立缓存分区。

液面有两层波动和上浮气泡，额度变化约 0.6 秒过渡。目标窗口隐藏时暂停动画；开启 macOS 的“减少动态效果”时保持静止。

## 开发

```sh
./scripts/test.sh                  # 32 个回归用例
./scripts/preview-animation.sh     # 合成额度交互预览，关闭窗口退出
./scripts/render-states.sh --animate  # 重新生成中文静态图与 GIF，需要 FFmpeg
./scripts/package.sh               # 测试、构建、签名、ZIP、校验和
```

`build/`、`dist/`、`.build/` 和运行数据不进入 Git。默认签名为 ad-hoc，尚未完成 Apple 公证。

- [定位、数据来源和已知限制](docs/behavior.md)
- [构建、签名和发布](docs/releasing.md)
- [更新记录](CHANGELOG.md)
- [用 Codex 复刻的提示词](docs/recreate-prompt.md)

执行 `./scripts/render-states.sh --english --animate` 可生成英文标签的预览。
