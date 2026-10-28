# QuotaDock

**中文** | [English](README.en.md)

在 macOS 的 Codex 头像上方显示剩余额度。液面表示比例，数字显示百分比，窗口移动时跟随，不挡鼠标点击。

当前版本 3.1.4 / build 27。

![QuotaDock 六种额度状态](https://raw.githubusercontent.com/wind8ai/quota-dock/main/docs/images/quota-dock.gif?v=f2ce9a4e8a5e)

图中额度为模拟值。[查看静态图](docs/images/quota-dock-states.png)

青蓝色表示剩余至少 50%，琥珀色表示 20% 到不足 50%，红色表示不足 20%。`0` 表示耗尽，`--` 表示暂时读不到有效额度。

## 构建与运行

需要 macOS 11+、Swift 5.3+，以及本机 Codex 生成的会话日志。已在 Apple Silicon 上验证。没有开发工具时，先运行 `xcode-select --install`。

```sh
git clone https://github.com/wind8ai/quota-dock.git
cd quota-dock
./scripts/build.sh
./scripts/sign.sh
open build/QuotaDock.app
```

默认使用 ad-hoc 签名，尚未经过 Apple 公证。应用没有 Dock 图标，也不自动添加登录项。退出时在活动监视器中结束 QuotaDock，或运行 `pkill -x QuotaDock`。

## 额度怎么算

读取本机 `CODEX_HOME/sessions` 下的 Codex 会话日志，默认目录是 `~/.codex/sessions`。不启动 CLI，不请求额度接口，也不读取登录令牌。

主窗口可见时约每 5 秒读取一次，隐藏时约每 30 秒读取。只使用 codex 额度回执，优先显示 5 小时窗口，否则显示每周窗口。数值按回执时间选取，允许上升或下降。

显示的是最近一次记录，不是服务端实时查询。空闲时保留读数，重启也能恢复；超过 15 分钟未更新时显示小钟标记并暂停气泡。只有没有记录或已到周期重置时间时才显示 `--`。[查看缓存状态](docs/images/quota-dock-cached-states.png)。切换账号或同时使用多个账号时，日志可能混在一起，不能保证与桌面当前选中的账号相同。

## 排查问题

检查窗口位置：

```sh
build/QuotaDock.app/Contents/MacOS/QuotaDock --diagnose
```

检查本地额度回执及其更新时间：

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
