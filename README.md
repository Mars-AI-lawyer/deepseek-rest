# DeepSeekBalance

macOS 菜单栏 DeepSeek 余额查询工具。在菜单栏显示 DeepSeek API 账户余额，悬停或点击即可查看充值余额与赠送余额的详细构成。

A macOS menu bar app for checking DeepSeek API account balance. Hover or click to view detailed breakdown of topped-up balance and grant balance.

![效果截图 / Screenshot](ScreenShot_2026-05-24_214514_617.png)

## 功能 / Features

- 菜单栏常驻，点击/悬停弹出余额面板
- 显示总余额、充值余额、赠送余额，含进度条可视化
- API Token 通过 macOS Keychain 安全存储
- 自动检测 Token 过期并提示重新输入
- 无第三方依赖，纯 Swift + AppKit，`swiftc` 直接编译

---

- Menu bar app with popover on click/hover
- Total balance, topped-up balance, and grant balance with progress bar visualization
- API Token stored securely via macOS Keychain
- Auto-detects token expiration and prompts for re-entry
- Zero third-party dependencies — pure Swift + AppKit, compiled with `swiftc`

## 系统要求 / System Requirements

- macOS 12.0+
- Apple Silicon (arm64)

## 安装 / Installation

### 从源码编译 / Build from Source

```bash
git clone https://github.com/Mars-AI-lawyer/deepseek-rest.git
cd deepseek_rest
./build.sh
open build/DeepSeekBalance.app
```

### 直接下载 / Direct Download

从 [Releases](https://github.com/Mars-AI-lawyer/deepseek-rest/releases) 页面下载最新版 `DeepSeekBalance-vX.X.X.zip`，解压后拖入 `/Applications`。

Download the latest `DeepSeekBalance-vX.X.X.zip` from the [Releases](https://github.com/Mars-AI-lawyer/deepseek-rest/releases) page, unzip, and drag to `/Applications`.

> 首次打开请**右键点击 App → 打开**（macOS 未签名应用提示）。右键打开一次后，后续双击即可正常启动。
> First launch: **Right-click the app → Open** (macOS unsigned app warning). After opening once via right-click, double-click will work normally.

首次启动会提示输入 DeepSeek API Token（格式：`sk-xxxxxxxxxxxxxxxxxxxxxxxx`），Token 将保存至系统钥匙串。

On first launch, enter your DeepSeek API Token (format: `sk-xxxxxxxxxxxxxxxxxxxxxxxx`). The token is saved to the system Keychain.

## 使用范围 / Scope

本工具仅调用 DeepSeek 官方 API `https://api.deepseek.com/user/balance` 查询账户余额信息。不收集、不上传任何用户数据，Token 仅存储于本地钥匙串。

This tool only calls the official DeepSeek API `https://api.deepseek.com/user/balance` to query account balance. No user data is collected or uploaded. The token is stored locally in the Keychain only.

## 已知限制 / Known Limitations

**日用量功能当前不可实现 / Daily usage tracking is currently not feasible**

原因 / Reasons:

1. **DeepSeek 未提供查询 token 日用量的官方 API。** `/user/balance` 接口仅返回账户余额（总余额、充值余额、赠送余额），不包含当日消耗统计。
2. **网页控制台已加强反爬。** 此前通过抓取 DeepSeek 网页控制台 usage 页面来获取日用量的方案，因目标页面反爬策略日趋严格，已不可行。

目前界面上仅展示余额信息，无法显示「今日消耗 token 数」「各模型用量分布」等日用量数据。

---

1. **DeepSeek does not provide an official API for daily token usage.** The `/user/balance` endpoint only returns balance info (total, topped-up, grant), without daily consumption statistics.
2. **Web console anti-scraping has been strengthened.** The previous approach of scraping the DeepSeek web console usage page is no longer viable due to increasingly strict anti-bot measures.

## PR 征集 / Call for Contributions

**期待高手贡献 PR，解决日用量获取问题 / Looking for contributors to solve daily usage tracking**

可能的探索方向 / Possible approaches:

- **Charles/Fiddler 抓包分析** — 对 DeepSeek 桌面端或手机端 App 进行抓包，寻找客户端内部使用的非公开接口
- **浏览器扩展方案** — 通过浏览器扩展在用户已登录的 DeepSeek 会话中注入脚本，读取页面数据
- **前端流量逆向** — 分析 DeepSeek 网页控制台的 JS bundle，提取内部 API 端点及鉴权逻辑

---

- **Packet capture (Charles/Fiddler)** — Inspect DeepSeek desktop or mobile app traffic to discover internal APIs
- **Browser extension** — Inject scripts into authenticated DeepSeek sessions to read usage data
- **Frontend reverse engineering** — Analyze the DeepSeek web console JS bundle to extract internal endpoints

### 提交 PR 前请注意 / PR Guidelines

- 保持项目的零第三方依赖原则（Swift 系统框架除外）
- 日用量数据展示需融入现有余额面板 UI 风格
- Token 仍然仅存储于本地钥匙串，不引入额外的网络传输
- 方案需稳定可用，不依赖随时可能失效的 hack

---

- Maintain the zero-dependency principle (Swift system frameworks only)
- Daily usage display should match the existing balance panel UI style
- Token stays in local Keychain — no additional network transmission
- The solution should be stable, not relying on hacks that may break at any time

## License

MIT
