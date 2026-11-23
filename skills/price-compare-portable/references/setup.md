# 无 Chromium / 登录态 / 定时任务

## 一、没有 Chromium 内核浏览器

按用户偏好三选一，不要替他决定：

| 方案 | 安装 | 优点 | 缺点 |
|---|---|---|---|
| Chrome / Edge / Brave | 官网下载 | 扩展生态完整，最稳 | 占内存、要迁移书签 |
| Playwright Chromium | `npx playwright install chromium` | 独立 profile，不污染日常浏览器 | 登录态要重新登，约 150MB |
| 系统 chromium | `brew install chromium` / `apt install chromium` / `winget install Chromium` | 轻量 | 版本可能旧，扩展兼容性看运气 |

装完都要把 OpenCLI 扩展加载进去（`chrome://extensions` → 开发者模式 → 加载已解压）。

## 二、登录态

必须由用户本人在目标浏览器里登录：

- 京东、淘宝、拼多多、什么值得买。
- 登录后不要退出；opencli 复用该浏览器的 Cookie。
- 你只做检测：跳登录页、`hasLogin=false`、验证码、空列表。
- 检测到登录墙就停，给用户明确指令：“在这个浏览器打开 <url> 登录一次，然后告诉我”。

**绝不做**：代登录、索要密码、导出/复制 Cookie、换号重试。

## 三、定时任务

| 系统 | 方式 | 注意 |
|---|---|---|
| macOS | launchd (`~/Library/LaunchAgents/*.plist`) | 没有 GUI session，扩展桥通常连不上 |
| Linux | cron / systemd timer | 同上，需要 `DISPLAY` 和已登录的桌面会话 |
| Windows | 任务计划程序 | 勾“只在用户登录时运行”才可能有 GUI |

结论：

- **需要登录态 + 扩展的比价，不要做定时任务**。
- 定时任务只适合抓公开静态页/接口（如慢慢买历史价、什么值得买列表页）。
- 如果用户坚持要定时，先明确告诉他“可能拿不到登录后的价格”，再决定。

## 四、依赖检查清单

- `opencli` 已安装（`opencli --version`）。
- `agent-reach` 已安装（`agent-reach channels` 有输出）。
- 浏览器扩展已连接（`opencli doctor` → `extensionConnected: true`）。
- 目标平台已登录。
- 网络能访问 `smzdm.com`、`manmanbuy.com`、`jd.com`、`taobao.com`、`pinduoduo.com`。

缺哪项补哪项，不要跳过。
