# 风控与反爬

## 原则

用**真人登录态的有头浏览器**，不做无头隐身对抗；遇验证码/登录墙**立即停**，交用户处理。

## 研究结论（2026-11）

- 无头 Chrome 的 WebGL、字体列表、屏幕参数与有头差异明显，更容易被识别；有头 + 虚拟显示更稳。
- Patchright（Playwright 的反检测分支）能消除 `navigator.webdriver` 等自动化标志，但仍非万能。
- 阿里 baxia 风控能区分 CDP 注入的鼠标事件与真实硬件事件：同一条轨迹，CDP 回放被判 `code=300`，真实光标回放 `code=0`。**滑块自动化不可靠，别硬做。**
- 验证失败后继续重试会延长风控时间；应熔断 + 冷却，而不是反复试。
- 参考项目：[ai-goofish-monitor](https://github.com/Usagi-org/ai-goofish-monitor)（Playwright + AI 过滤 + 随机延迟）、[xianyu-super-butler 部署文档](https://github.com/23Star/xianyu-super-butler/blob/main/docs/deployment.md)（Patchright / Xvfb / 熔断）。

## 我们的规则

1. 只用有头 Brave + 已登录 profile；不用 `--headless`。
2. 单平台单次 ≤5 请求；每步 2–5s 随机延迟；**不并发多平台**（浏览器桥只有一个）。
3. 遇到以下信号立即停，交用户手动处理：
   - 302 到 `passport.*/login`、`SECURITY_BLOCK`、`Navigation rejected`
   - 验证码/滑块、空列表、价格全 0
4. 不自动拖滑块、不换号、不代理轮换、不伪造指纹。
5. 失败冷却 ≥30 分钟；同一平台两次任务间隔 ≥10 分钟。
6. 只读：不下单、不领券、不加购。

## 平台信号表

| 平台 | 风控信号 | 处理 |
|---|---|---|
| 淘宝 | `SECURITY_BLOCK`、滑块 | 停，用户在浏览器处理 |
| 闲鱼 | 滑块、跳登录、`code=300` | 停，不自动过滑块 |
| 1688 | `Navigation rejected`、跳登录 | 停，先让用户登录 |
| 拼多多 | 空 `rawData`、跳 login.html、`AUTH_REQUIRED` | 停，冷却 30 分钟 |
| 唯品会 | 302 `passport.vip.com/login` | 停，用户登录后重跑 |
| 京东 | 验证码、跳登录、价格空白 | 停 |
| 什么值得买 | 403、验证码 | 停，换关键词不换号 |

## 为什么不用无头

- 本机用 Brave 的真实 profile，登录态、Cookie、指纹都是真的，比任何“隐身脚本”稳。
- 真无头 + 指纹伪装是军备竞赛，维护成本高，且一旦被识别会连累账号。
- 我们的目标是“偶尔查一次价”，不是批量采集；频率低本身就是最好的反风控。
