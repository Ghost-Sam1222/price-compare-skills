# 比价 Skills（price-compare-skills）

给 AI Agent 用的**只读多平台比价**技能包：从什么值得买 / 慢慢买 / 小红书找爆料并核验评论与时效，再到京东、淘宝、拼多多、唯品会、1688、闲鱼查实时价，输出带**到手价、折合单价、优惠条件、难度、时效、假优惠标记**的比价表；到店吃饭/门票按 **闲鱼券 → 美团 → 抖音/抖省省** 的顺序比。

> 只读：不下单、不领券、不代登录、不碰密码。遇到验证码/登录墙一律停下，交给用户。

## 包含什么

```
skills/
├── price-compare-personal/   # macOS 自用版：Brave + OpenCLI 扩展，后台唤醒
└── price-compare-portable/   # 跨平台分享版：Windows/macOS/Linux，先探测环境
adapters/
├── vipshop-search.js         # 唯品会搜索适配器（需登录）
└── pinduoduo-search.js       # 拼多多搜索适配器（修复入口参数，需登录）
```

## 前置条件

- [opencli](https://github.com/jackwener/opencli)（浏览器扩展 + 命令行）
- [agent-reach](https://github.com/...)（爆料/网页读取；本仓库不附带）
- 一个已登录的 Chromium 浏览器（Chrome / Edge / Brave）

## 安装

1. 把 `skills/` 下的目录放进你的技能目录：
   - macOS / Linux：`~/.agents/skills/`
   - Windows：`%USERPROFILE%\.agents\skills\`
2. 安装适配器（可选，但唯品会/拼多多需要）：

```bash
mkdir -p ~/.opencli/clis/vipshop ~/.opencli/clis/pinduoduo
cp adapters/vipshop-search.js ~/.opencli/clis/vipshop/search.js
cp adapters/pinduoduo-search.js ~/.opencli/clis/pinduoduo/search.js
```

3. 在浏览器里登录：京东、淘宝、拼多多、唯品会、什么值得买。
4. 自用版先跑 `bash skills/price-compare-personal/scripts/bootstrap.sh`；分享版跑 `bash skills/price-compare-portable/scripts/detect-env.sh`。

## 使用

直接说人话：

- “比价 超能双离子洗衣液 11 斤”
- “这瓶滴露 1.8L 现在算好价吗”
- “我要去南京大排档金陵style店吃饭，看看有没有优惠套餐”
- “帮我看看 XX 门票哪里便宜”

Agent 会按 `SKILL.md` 的流程走：找爆料 → 核验评论/时效 → 查平台 → 出表。

## 平台支持

| 场景 | 平台 | 方式 |
|---|---|---|
| 普通网购 | 京东 / 淘宝 / 拼多多 / 唯品会 / 1688 | opencli 适配器 search |
| 急用现货/优惠券 | 闲鱼 | `opencli xianyu search`（不用于蹲漏价） |
| 本地生活 | 美团 / 抖省省 | 什么值得买爆料 |
| 抖音商城 | — | 无网页/适配器，手动链接，不自动搜 |
| 快手 / 苏宁 | — | browser 兜底或跳过 |

## 风控边界

- 只用有头浏览器 + 已登录 profile，不用无头。
- 单平台 ≤5 请求，2–5s 随机延迟，不并发多平台。
- 遇 `SECURITY_BLOCK`、跳登录、验证码、空列表 → 立即停。
- 不自动拖滑块、不换号、不代理轮换、不伪造指纹。
- 不做定时全自动比价（无 GUI session 时扩展桥不可用）。

详见 `skills/price-compare-personal/references/risk-control.md`。

## 已知限制

- **抖音商城**：网页端只有 App 下载页（`mall.douyin.com`），`douyin.com/mall`、`/shop`、`haohuo` 均为 404/壳页；不接自动搜索，只能手动看分享链接。
- **拼多多**：`search` 需要登录态；`detail` 子命令不存在，价格只从 `search` 的 `price` / `groupPrice` 拿。
- **唯品会**：搜索需登录；未登录会 302 到 `passport.vip.com/login`，适配器抛 `AuthRequiredError`。
- **1688**：需登录，风控可能返回 `Navigation rejected`，遇到就停。
- **闲鱼**：只适合急用现货/优惠券；蹲漏价请用 ai-goofish-monitor。
- **快手 / 苏宁 / 美团 / 抖省省**：没有商品搜索适配器；美团/抖省省走什么值得买爆料。
- **定时任务**：无 GUI session 时浏览器扩展桥不可用，不要承诺全自动比价。
- **价格随账号变化**：PLUS / 88VIP / 百亿补贴 / 新人券，表里必须标账号条件。

## 许可

MIT，见 [LICENSE](LICENSE)。第三方项目与灵感来源见 [NOTICE.md](NOTICE.md)。

## 免责声明

本项目只提供比价方法，不构成购买建议。价格随时效变化，以平台结算页为准。请遵守各平台用户协议；不要用于批量爬取、刷单、抢购或绕过风控。
