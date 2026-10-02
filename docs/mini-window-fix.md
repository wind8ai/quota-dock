# 3.0.1：开启 mini 时额度条消失

日期：2026-10-02。版本：3.0.1/build 14。

## 原因

开启 mini／宠物后，ChatGPT 新增层级为 3 的浮动窗口。现场记录的透明窗口边界为 `x=589,y=-44,width=1128,height=1869`，尺寸比主窗口还大。旧规则接受层级 0 到 99 的大窗口，枚举时先遇到它，就把它当成了账号栏所在的主窗口。

由该边界计算出的额度条顶点为 `x=599,y=1686`，超出了当前屏幕。坐标转换返回空值，应用因此主动隐藏额度条。主窗口实际上仍可见，边界为 `x=0,y=37,width=1512,height=945`。这次消失由选错窗口触发。

## 修复

将缓存校验和枚举选择共同使用的窗口筛选放入 `Sources/QuotaCore/AccountWindowSelector.swift`，只接受 `CGWindowLevelForKey(.normalWindow)` 的主窗口。浮动 mini 不会替换主窗口头像锚点；主窗口实际不可见时仍按原规则隐藏。额度读取、缓存和动画没有改变。

## 验证

- 原始生产定位器在用户保持 mini 开启的情况下连续两次失败：`tracker_has_origin=false`，同时主窗口仍可见。
- 捕获的主窗口与 mini 窗口边界组成最小回归输入。旧规则下 `testMiniBeforeMainKeepsMainAvatarAnchor` 失败，错误为 `Floating mini window replaced the main-window anchor`；修复后通过。
- `./scripts/test.sh` 的 27 个用例全部通过，覆盖 mini 优先出现、只有 mini 和隐藏主窗口、窗口顺序变化与负坐标显示器。
- `./scripts/build.sh` 与 `./scripts/sign.sh` 通过，已启动新版本地应用。
- 用户保持 mini 开启时，现场同时观察到 mini、主窗口和 QuotaDock 可见。额度条边界为 `x=10,y=843,width=32,height=96`，随后多次定位刷新仍可见。

本地局部截图及元数据位于被忽略的 `artifacts/mini-repro/`，真实额度截图不入 Git。现有用户短文修改及 `.agents/` 保留。
