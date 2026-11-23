# 浏览器：路径、启动、扩展安装

## 各平台 profile 路径

| 浏览器 | macOS | Windows | Linux |
|---|---|---|---|
| Chrome | `~/Library/Application Support/Google/Chrome` | `%LOCALAPPDATA%\Google\Chrome\User Data` | `~/.config/google-chrome` |
| Brave | `~/Library/Application Support/BraveSoftware/Brave-Browser` | `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data` | `~/.config/BraveSoftware/Brave-Browser` |
| Edge | `~/Library/Application Support/Microsoft Edge` | `%LOCALAPPDATA%\Microsoft\Edge\User Data` | `~/.config/microsoft-edge` |
| Chromium | `~/Library/Application Support/Chromium` | `%LOCALAPPDATA%\Chromium\User Data` | `~/.config/chromium` |
| 360 极速 | `~/Library/Application Support/360Chrome/Chrome` | `%LOCALAPPDATA%\360Chrome\Chrome\User Data` | 无官方版 |
| 360 安全 | 无 | `%APPDATA%\360se6\User Data` | 无 |
| QQ 浏览器 | `~/Library/Application Support/QQBrowser` | `%LOCALAPPDATA%\Tencent\QQBrowser\User Data` | 无 |
| 搜狗 | 无 | `%LOCALAPPDATA%\SogouExplorer\User Data` | 无 |

`Default` 是默认 profile；多 profile 时还有 `Profile 1`、`Profile 2`。

## 启动命令（后台，不抢焦点）

macOS：

```bash
open -g -a "Brave Browser" --args --profile-directory="Default"
open -g -a "Google Chrome" --args --profile-directory="Default"
```

Windows（PowerShell）：

```powershell
Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" -ArgumentList '--profile-directory="Default"'
```

Linux：

```bash
google-chrome --profile-directory="Default" >/dev/null 2>&1 &
```

## 扩展安装

1. 从 [opencli releases](https://github.com/jackwener/opencli/releases) 下载扩展包并解压。
2. 打开 `chrome://extensions`（Edge 是 `edge://extensions`）。
3. 打开右上角“开发者模式”。
4. 点“加载已解压的扩展程序”，选解压后的目录。
5. 确认扩展图标出现，跑 `opencli doctor` 看 `extensionConnected: true`。

## 国产浏览器注意

- 360 / QQ / 搜狗 / 2345 等是魔改 Chromium，**可能禁用“加载已解压扩展”**，或加载后不生效。
- 即使能装，profile 路径和启动参数也可能不同，`opencli` 的连接行为不可预测。
- 处理顺序：先试一次 → 失败就转独立 Chromium → **不要超过 10 分钟**。
- 不要建议用户为了比价卸载日常浏览器；用独立 Chromium 更干净。

## 无头模式

- `--headless` 下扩展不保证加载，Brave 尤其不确定。
- 需要后台运行时，用“后台窗口 + 不抢焦点”，不要用真无头。
- 定时任务里没有 GUI session，扩展桥基本不可用，见 `setup.md`。
