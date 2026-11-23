# 爆料源：入口、字段、评论提取

## 什么值得买（主源）

搜索：

```bash
opencli smzdm search "<关键词>" --limit 20
```

返回字段：`title`、`price`（带条件，如“64.53元（需买2件，需用券）”）、`mall`（京东/天猫超市/拼多多/…）、`updated_at`、`url`、`comments`、`zhi_count`。

**搜索只给摘要，必须二次读页**：

```bash
agent-reach web read "<url>"
```

如果评论没出来（JS 渲染），换浏览器：

```bash
opencli browser open "<url>" --session zdm --window background
sleep 4
opencli browser eval --session zdm "(async()=>{window.scrollTo(0,document.body.scrollHeight);await new Promise(r=>setTimeout(r,1500));return (document.body.innerText||'').split('\n').filter(l=>/·|回复|评论/.test(l)).slice(0,40).join('\n')})()"
opencli browser close --session zdm
```

从页面正文里提取：

- `爆料原文`：活动价、券、凑单、实付——这是到手价的唯一可信来源。
- `更新时间`：判断时效。
- 评论区：只取最近 30 天，按关键词抽样。

评论关键词分三组：

| 组 | 关键词 | 含义 |
|---|---|---|
| 失效 | 失效、过期、没了、下架 | 直接淘汰 |
| 涨价 | 涨价、变价、贵了、不是这个价 | 降级或复核 |
| 体验 | 没货、难抢、客服、翻车、真香、发货 | 作风险备注 |

规则：至少看 3 条不同用户的评论再下结论；单条差评不当结论；评论日期比内容更重要。

## 慢慢买（历史价 / 平台低价）

**不要用 `agent-reach web read`**：jina 对 manmanbuy 返回 422，读不到。
**不要用 `Default.aspx?key=`**：它会 302 到 `pc/search/result` 并把已编码的关键词再编码一次，结果变成乱码、搜不到。

可用方法：真实浏览器直接打开 `pc/search/result` 直链（关键词只编码一次）：

```bash
opencli browser open "https://s.manmanbuy.com/pc/search/result?c=discount&keyword=<URL编码一次的关键词>" --session mmb --window background
sleep 5
opencli browser eval --session mmb "document.body.innerText.slice(0,4000)"
opencli browser close --session mmb
```

返回的列表里直接带：

- `30天新低` / `60天新低` / `180天新低` / `历史新低` 标签
- `已结束` 标记（过期爆料）
- 日期 + 平台（天猫超市/京东/…）+ 价格 + 淘金币抵扣

这就是“史低价参考”的数据来源，比 `HistoryLowest.aspx` 更省事。`HistoryLowest.aspx` 需要商品 ID，暂未验证。

注意：

- 反爬较强，单次会话最多 2–3 次请求；失败就跳过，不要反复试。
- 慢慢买的价格是“抓取时价”，可能滞后；只作历史参考，最终以平台结算页为准。
- 历史低价不等于现在能买到，必须标日期和“已结束”。

## 小红书（辅助）

```bash
agent-reach xiaohongshu search "<关键词>" --limit 10
agent-reach xiaohongshu read "<笔记链接>"
```

用途：判断“最近有没有人买过/踩雷/晒单”，不单独作为价格依据。

注意：

- 软广、返利链接多，看到“链接在评论区/私信”直接跳过。
- `read` 只返回文字描述，不要声称看懂了图片或视频。
- 需要登录时 `agent-reach login xiaohongshu`，由用户本人操作。

## 交叉核验顺序

1. 什么值得买爆料价 → 2. 慢慢买历史价（判断是否真低）→ 3. 平台实时价（判断现在能不能买到）→ 4. 小红书（判断有没有坑）。

任何一步拿不到，就在表里标“未核验”，不要编。
