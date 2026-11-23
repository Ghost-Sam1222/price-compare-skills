# 购物平台：命令、字段、降级路径

## 京东

```bash
opencli jd item <sku>          # 价格、店铺、规格、主图
opencli jd detail <sku>        # 商品详情
opencli jd reviews <sku>       # 评价
opencli jd cart                # 购物车（只读）
```

- `search` 可用：`opencli jd search "<关键词>" --limit 30`，SKU 从结果拿。
- `item` 的价格是页面价，**不含券后**；券后价看爆料原文或结算页。
- 京东价格与 PLUS 会员、品类券、首购礼金相关，表里标“账号条件”。

## 淘宝 / 天猫

```bash
opencli taobao detail <id>     # 商品详情
opencli taobao cart            # 购物车（只读）
```

- `search` 可用：`opencli taobao search "<关键词>" --limit 40 --sort price`，商品 ID 从结果拿。
- `search` 可能返回 `SECURITY_BLOCK`（淘宝安全验证）：停下，让用户在浏览器手动处理，不要重试。
- 天猫超市价格与 88VIP、淘金币、超神卡、店铺券相关，条件多，必须逐条写清。

## 拼多多

```bash
opencli pinduoduo search "<关键词>" --limit 10
```

- `search` 可用，首屏 20 条。
- 没有 `detail` 子命令（`opencli pinduoduo --help` 只有 `search`）。价格只从 `search` 结果里的 `price` / `priceLabel` / `groupPrice` 拿，或让用户在 App 看。
- 百亿补贴、福袋券是账号相关且随机的，默认不写进主表；要写就标“不确定”。

## 唯品会

```bash
opencli vipshop search "<关键词>" --limit 20
```

- 本地适配器在 `~/.opencli/clis/vipshop/search.js`（2026-11-22 起）。
- 返回：标题、特卖价、原价、折扣、商品 ID、链接；首屏 50 条，适配器暂只取第一页。
- **必须登录**：未登录会 302 到 `passport.vip.com/login`，适配器抛 `AuthRequiredError`。让用户在那个浏览器登录一次再重跑。
- 价格是「特卖价」，未必是最终到手价；唯品会的券/会员价在结算页，比价表里标“页面价”。

## 1688

```bash
opencli 1688 search "<关键词>" --limit 20
opencli 1688 item <id>
```

- 需登录；实测可能返回 `Navigation rejected`（风控/未登录），遇到就停，不要重试。
- 适合找同款源头价，不适合买一件；注意起订量和运费。

## 闲鱼

```bash
opencli xianyu search "<关键词>" --limit 20 --min-price 100 --max-price 3000 --province 广东
opencli xianyu item <item_id>
```

- 实测可用，返回标题、价格、地区、item_id、链接。
- **定位：急用现货/优惠券**（券码、门票、代下单、急用配件）；不用于“蹲漏价”。
- 蹲二手/长期监控用 [ai-goofish-monitor](https://github.com/Usagi-org/ai-goofish-monitor)（推送 + 数据库），不在本 skill 范围。
- 优先筛：现货、可立即发货、验货宝、信用极好；不蹲拍卖/预售。
- 二手价，必须看成色、验货宝、卖家信用；**不能和全新价直接比**。
- 遇滑块/登录墙立即停，不自动过滑块。

## 抖音商城

- `mall.douyin.com` 只是 App 下载落地页（263 字符），无搜索/商品。
- `douyin.com/mall`、`/shop`、`haohuo` 都是 404 或壳页；App-first。
- APK 套壳分析不做：抖音商城是原生 + 签名接口，REA 成本高、收益低；产品页 H5 也需登录/签名。
- 不接自动比价；用户发来分享链接时，只能手动打开看。**不要假装能搜。**

## 快手 / 苏宁

- 没有适配器；用 `opencli browser open "<搜索页 URL>" --session ks --window background` 打开搜索页人工看，或跳过。
- 不要写进主表“自动比价”，标“未核验”。

## 美团 / 抖省省（本地生活）

- 顺序：**闲鱼券 → 美团 → 抖音/抖省省**；闲鱼一般只有大店/连锁有券。
- 闲鱼券必查：适用门店、时段、有效期、是否预约、限桌/限人数。
- 美团/抖音：看是否限新客、限工作日、需提前预约。
- 没有商品搜索适配器；走爆料：`opencli smzdm search "美团 <门店名>"` 或 `agent-reach web read` 读爆料页。
- 比价维度是“到店套餐/外卖红包/酒店”，不是元/kg；输出用“套餐名 + 到手价 + 适用门店/城市”。
- 旅游/门票：比的是日期、城市、实名、入园时间、退改规则，必须写有效期。

## 通用降级：browser

任何平台拿不到结构化数据时：

```bash
opencli browser open "<url>" --session pc --window background
opencli browser eval --session pc "document.body.innerText.slice(0,3000)"
opencli browser close --session pc
```

- 每次用独立 `--session`，用完关闭，避免多个任务抢同一个 tab。
- 遇到登录墙/验证码：停止，提示用户手动处理；不要换号、不要绕过。
- 页面是 JS 渲染时，`eval` 前先 `sleep 2-4`，或轮询目标元素。

## 频率与风控

| 平台 | 单次会话上限 | 触发风控的信号 |
|---|---|---|
| 京东 | 5 次 | 验证码、跳登录、价格空白 |
| 淘宝 | 5 次 | 滑块、跳登录 |
| 拼多多 | 5 次 | `AUTH_REQUIRED`、空 `rawData`、跳 login.html |
| 唯品会 | 5 次 | 跳 `passport.vip.com/login`、空列表、验证码 |
| 什么值得买 | 10 次 | 页面 403、验证码 |

触发后：停止该平台，记录“未核验”，继续其他平台。不要重试超过 2 次。

## 价格口径

- **到手价** = 标价 − 券 − 立减 − 平台补贴 + 运费（免运费写 0）。
- **折合单价** = 到手价 ÷ 规格数量（kg/L/片/包），保留两位小数。
- **账号条件**：PLUS / 88VIP / 新人 / 首购 / 会员价，没有就写“无”。
- **含税**：国内平台含 13% 增值税；海淘单独标“不含税/含税”。
