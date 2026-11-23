---
name: price-compare-personal
description: 在 macOS 本机做多平台比价。从什么值得买、慢慢买、小红书找爆料并核验评论与时效，再到京东、淘宝、拼多多、唯品会、1688、闲鱼查实时到手价；美团/抖省省走本地生活爆料。输出带难度、账号条件、时效标注、假优惠识别的比价表。Use when the user asks 比价、找好价、查历史价、这个值不值得买，or mentions 什么值得买/慢慢买/京东/淘宝/拼多多/唯品会/1688/闲鱼/美团/抖音.
---

# 多平台比价（自用版 · macOS）

## 前置检查（每次先跑）

```bash
bash scripts/bootstrap.sh
```

脚本会：

1. `opencli doctor` 检查扩展桥；未连接则**后台唤醒 Brave**（不抢焦点），等最多 10s 再查。
2. `agent-reach doctor --text` 检查渠道；缺 xiaohongshu 时提示 `agent-reach add xiaohongshu`。
3. 输出 `{"opencli":"ok|down|missing","agent_reach":"ok|degraded|missing","browser":"brave|none"}`（`browser` 为 `brave` 表示本次已后台唤醒 Brave，`none` 表示未唤醒）。

**不要**在扩展未连接时硬跑 `opencli smzdm` / `jd` / `pinduoduo`，会直接报 `BROWSER_CONNECT`。

## 工作流

1. **先判场景 + 锁定标的**：
   - 普通网购 → 京东 / 淘宝 / 拼多多 / 唯品会 / 1688
   - 二手 → 闲鱼（只用于急用现货/优惠券；蹲漏价用 ai-goofish-monitor）
   - 本地生活（吃饭/旅游）→ 美团 / 抖省省，走爆料，不走商品搜索
   - 药品 / 化妆品 / 保健食品 / 器械 → 先过品类闸门（见下）
   - 确认商品名、规格、数量、心理价位；规格不同不能直接比价（如 5.5kg vs 5.9kg、8 斤 vs 6kg）。
2. **找爆料**（并行）：
   - `opencli smzdm search "<关键词>" --limit 20`
   - 慢慢买：`opencli browser open "https://s.manmanbuy.com/pc/search/result?c=discount&keyword=<编码一次的关键词>" --session mmb --window background`，再 `opencli browser eval --session mmb "document.body.innerText.slice(0,4000)"`，用完 `opencli browser close --session mmb`（`agent-reach web read` 对该站不可用，详见 `references/sources.md`）
   - 可选：`agent-reach xiaohongshu search "<关键词>" --limit 10`
3. **核验爆料（关键，不能省）**：
   - 对每条候选，`agent-reach web read "<爆料 URL>"` 读正文 + 评论。
   - 提取：更新时间、到手价、优惠构成、评论里的“失效/涨价/没货/难抢/客服”。
   - 超过 7 天的爆料降级；8–30 天进“历史价参考”，>30 天或已过期进“史低价参考”，都不进主表。
4. **查平台实时价**：
   - 京东：`opencli jd search "<关键词>" --limit 30`、`opencli jd item <sku>`、`opencli jd reviews <sku>`
   - 拼多多：`opencli pinduoduo search "<关键词>" --limit 10`
   - 淘宝：`opencli taobao search "<关键词>" --limit 40 --sort price`、`opencli taobao detail <id>`
   - 唯品会：`opencli vipshop search "<关键词>" --limit 20`（需登录态）
   - 1688：`opencli 1688 search "<关键词>" --limit 20`（需登录，可能 `Navigation rejected`）
   - 闲鱼：`opencli xianyu search "<关键词>" --limit 20`（只用于急用现货/优惠券；蹲漏价用 ai-goofish-monitor；注意成色/验货宝）
   - 美团/抖省省：无商品搜索，走 `opencli smzdm search "美团 团购"` 爆料
   - 拿不到 SKU/ID 时：`opencli browser open <url> --session pc --window background` + `opencli browser eval --session pc "document.body.innerText.slice(0,3000)"`，用完 `opencli browser close --session pc`。
5. **出表**：按 `references/output.md` 的模板。主表只列当前可买，历史价单独折叠。

## 本地生活：到店套餐 / 门票

用户说“去 XX 店吃饭，看看有没有优惠套餐/团购”或“XX 门票”时，按这个顺序：

1. **闲鱼先看券**：`opencli xianyu search "<门店名> 代金券"` / `"<门店名> 团购"`。
   - 一般只有大店/连锁才有人卖券，小店很少。
   - 必须确认：适用门店（是不是这家）、适用时段（午市/晚市/周末）、有效期、是否要预约、是否限桌/限人数。
   - 闲鱼价不一定最低，只作比价项之一。
2. **美团**：`opencli smzdm search "美团 <门店名>"` 找爆料；或 `opencli browser open "<美团搜索页 URL>" --session mt --window background` 人工看，看完 `opencli browser close --session mt`。
3. **抖音/抖省省**：`opencli smzdm search "抖音 <门店名> 团购"` 找爆料；或手动打开。
4. **比价**：同套餐/同面额/同时段才能比；闲鱼券要算“沟通+预约成本”，美团/抖音要看“是否限新客”。
5. **出表**：渠道 | 套餐/面额 | 到手价 | 适用门店/时段 | 有效期 | 难度 | 风险。

门票同理：闲鱼票 + 美团/抖音门票，注意实名、入园时间、退改规则。

## 品类闸门（借鉴现有比价 skill）

- 普通商品：正常比价。
- 药品：只认「国药准字 + OTC/RX」；默认排除妆字号 / 食字号 / 健字号 / 消字号 / 械字号。
- 化妆品 / 保健食品 / 器械：先确认批准文号类别，不同类别不混表。
- 拿不到文号写“未核实”，不编造。

## 三条硬规则

1. **先判品类**：药品/化妆品/保健/器械不混表。
2. **每平台至少 3–5 屏**：`search --limit` 至少 20；browser 至少滚 3 屏，别只看首屏。
3. **实付公式写死**：实付 = 标价 + 运费 − 券 − 立减 − 补贴；券门槛、凑单金额必须写。

## 来源规则

- **什么值得买**：主爆料源。`search` 只给摘要（标题/价格/渠道），**必须二次读页**拿评论和更新时间。
- **慢慢买**：历史价 / 平台低价。只能用真实浏览器打开 `s.manmanbuy.com/pc/search/result?c=discount&keyword=`（关键词只编码一次）；`agent-reach web read` 对该站不可用，`Default.aspx?key=` 会二次编码。`HistoryLowest.aspx` 需商品 ID，暂未验证。反爬较强，失败就跳过，不要反复试。
- **小红书**：辅助，只作“最近有没有人买过/踩雷”的旁证。软广多，不单独作为价格依据。

## 平台规则

- 京东：`search` 搜商品（max 30），`item` 给价格/店铺/规格，`reviews` 给评价。
- 淘宝：`search` 搜商品（max 40，支持 `--sort price`），`detail` 给详情，`reviews` 给评价。
- 拼多多：只有 `search`（H5 首屏，需登录态）；没有 `detail` 子命令，价格只从 `search` 的 `price` / `groupPrice` 拿。
- 唯品会：`search` 返回标题/特卖价/原价/折扣；需登录，未登录抛 `AuthRequiredError`。
- 所有平台价格**与账号相关**（PLUS / 88VIP / 百亿补贴 / 新人券），表里必须标“账号条件”。

## 输出

见 `references/output.md`。硬性要求：

- 主表列：商品 | 规格 | 平台 | 到手价 | 折合单价 | 优惠条件 | 难度 | 时效 | 链接
- 难度用 易/较易/较难/难/很难；“很难”（拼团/福袋随机券）默认不推荐
- 已过期的不进主表，进“史低价参考”并标日期
- 最后给一句结论：最推荐哪个、为什么、风险是什么

## 边界

- 只读：不下单、不领券、不代登录、不碰密码。
- 每平台单次会话 ≤5 次请求；遇验证码/登录墙立即停，让用户手动处理。
- 不换号、不绕过风控、不刷福袋券。
- 分享给别人用 `price-compare-portable`，不要让对方直接套这份 macOS 配置。

## 参考

- `references/sources.md`：三个爆料源的入口、字段、评论提取
- `references/platforms.md`：京东/淘宝/拼多多的命令与降级路径
- `references/output.md`：表格模板、难度分级、时效规则
- `references/pricing.md`：到手价、单价换算、假优惠识别
- `references/risk-control.md`：风控信号与停止规则
