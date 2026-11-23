---
name: price-compare-portable
description: 跨平台比价（Windows/macOS/Linux 通用）。探测本机浏览器与 opencli/agent-reach 环境，按结果引导安装扩展或改用独立 Chromium，再按什么值得买→慢慢买→京东/淘宝/拼多多/唯品会/1688/闲鱼的流程出比价表；美团/抖省省走本地生活爆料。Use when 用户要分享/复用比价流程、换电脑、或问“我这台机器怎么跑比价”.
---

# 多平台比价（分享版 · 跨平台）

这份 skill 不假设你的环境。先探测，再选路径，不要直接照搬 macOS 的命令。

## 第一步：探测环境

macOS / Linux：

```bash
bash scripts/detect-env.sh
```

Windows（PowerShell）：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/detect-env.ps1
```

输出示例：

```json
{"os":"macos","browsers":["Brave Browser","Google Chrome"],"opencli":"ok","extension":"connected","agent_reach":"ok"}
```

## 第二步：按结果选路径

### 路径一：有 Chromium 系浏览器 + 扩展已连接

直接用。跳到“第三步”。

### 路径二：有 Chromium 系浏览器，但扩展没装/没连

1. 让用户选一个**日常在用**的 Chromium 浏览器（Chrome / Edge / Brave / 其他）。
2. 安装 OpenCLI 扩展：打开 `chrome://extensions` → 开发者模式 → “加载已解压的扩展程序” → 选扩展目录。扩展包从 [opencli releases](https://github.com/jackwener/opencli/releases) 下载。
3. 重跑 `opencli doctor`，确认 `extensionConnected: true`。
4. 如果用户用的是 360/QQ/搜狗等国产浏览器：先确认它是否允许“开发者模式加载解压扩展”。不允许就放弃，转路径三——**不要在这上面耗超过 10 分钟**。

### 路径三：没有 Chromium，或国产浏览器装不上扩展

给用户三档选择，让他挑：

| 方案 | 适合 | 代价 |
|---|---|---|
| 装 Chrome / Edge / Brave | 愿意日常用 | 占内存、要迁移书签 |
| 装 Playwright 自带 Chromium | 只想跑自动化，不想装大浏览器 | 独立 profile，登录态要重新登 |
| 系统包管理器装 chromium | Linux 用户 | 版本可能旧 |

Playwright Chromium 安装：

```bash
npx playwright install chromium
```

装完把 opencli 扩展加载进这个 Chromium，再用它跑比价。**不要**用 `--headless` 跑扩展，扩展在无头模式下不保证加载。

## 第三步：登录态

- 让用户**本人**在选定的浏览器里登录：京东、淘宝、拼多多、什么值得买。
- 你只检测登录墙（跳登录页、`hasLogin=false`、验证码），检测到就停，提示用户手动登录。
- 不代登录、不索要密码、不碰 Cookie。

## 第四步：比价流程

和自用版一致：

1. 先判场景：普通网购（京东/淘宝/拼多多/唯品会/1688）、二手（闲鱼，仅急用现货/优惠券；蹲漏价用 ai-goofish-monitor）、本地生活（美团/抖省省，走爆料）；再锁定商品名 + 规格 + 数量。
2. 找爆料：`opencli smzdm search`、慢慢买搜索页（只能用真实浏览器开 `pc/search/result`，`agent-reach web read` 对该站不可用）、可选小红书。
3. 核验：读爆料页正文 + 评论，看过期/涨价/没货关键词。
4. 查平台：京东 `search`/`item`/`reviews`、淘宝 `search`/`detail`、拼多多 `search`、唯品会 `vipshop search`、1688 `search`、闲鱼 `xianyu search`；本地生活走 `smzdm search`。拿不到就用 `opencli browser open` / `opencli browser eval`（都要带 `--session <名字>`）。
5. 出表：按 `references/output.md`。
6. 本地生活（到店/门票）：闲鱼券 → 美团 → 抖音/抖省省，比同套餐同时段；闲鱼券查适用门店/时段/有效期/是否预约。

## 三条硬规则

1. 先判品类：药品只认「国药准字 + OTC/RX」，化妆品/保健食品/器械不混表。
2. 每平台至少 3–5 屏，`search --limit` 至少 20。
3. 实付 = 标价 + 运费 − 券 − 立减 − 补贴；券门槛、凑单金额写清。

## 可选：唯品会

唯品会不在 opencli 内置站点里，需要本地适配器（随包在 `adapters/vipshop-search.js`）：

```bash
mkdir -p ~/.opencli/clis/vipshop
cp adapters/vipshop-search.js ~/.opencli/clis/vipshop/search.js
opencli vipshop search "连衣裙" --limit 10
```

- 需要用户在该浏览器登录唯品会；未登录会 302 到 `passport.vip.com/login`，适配器抛 `AuthRequiredError`。
- 返回标题、特卖价、原价、折扣；首屏 50 条，只取第一页。

## 抖音商城（不可自动搜索）

- `mall.douyin.com` 只是 App 下载落地页；`douyin.com/mall`、`/shop`、`haohuo` 是 404/壳页。
- 没有搜索适配器，**不要假装能搜**；用户发来分享链接时只能手动打开看。
- 团购/本地生活走爆料：`opencli smzdm search "抖音 <门店名>"`。

## 第五步：定时任务（可选，先读这段）

macOS launchd / Linux cron / Windows 任务计划程序里**没有 GUI session**，浏览器扩展桥通常连不上。所以：

- 定时任务只适合“抓静态页/公开接口”的轻量比价。
- 需要登录态和扩展的，不要做定时，做成“用户在场时手动触发”。
- 别向用户承诺“全自动每天比价”，做不到。

## 边界

- 只读：不下单、不领券、不代登录。
- 每平台单次会话 ≤5 次请求；遇验证码/登录墙立即停。
- 不换号、不绕过风控。
- 国产浏览器魔改内核的行为不可预测，探测失败就转独立 Chromium，不要硬试。

## 参考

- `references/browsers.md`：各浏览器 profile 路径、启动命令、扩展安装
- `references/setup.md`：无 Chromium 的三档方案、登录、定时任务
- `references/output.md`：表格模板、难度分级、时效规则
- `references/pricing.md`：到手价、单价换算、假优惠识别
- `references/risk-control.md`：风控信号与停止规则
