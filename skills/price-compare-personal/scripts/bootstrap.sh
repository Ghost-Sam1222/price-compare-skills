#!/usr/bin/env bash
# 检查 opencli 扩展桥 + agent-reach，必要时后台唤醒 Brave（不抢前台焦点）。
# 用法: bash scripts/bootstrap.sh
# 输出: {"opencli":"ok|down|missing","agent_reach":"ok|degraded|missing","browser":"brave|none"}
# browser=brave 表示本次已后台唤醒 Brave；none 表示未唤醒（不代表没有浏览器）。

set -uo pipefail

opencli_status="missing"
agent_reach_status="missing"
browser="none"

if command -v opencli >/dev/null 2>&1; then
  opencli_status="down"
  doc="$(opencli doctor 2>/dev/null || true)"
  if printf '%s' "$doc" | grep -q '"extensionConnected":true'; then
    opencli_status="ok"
  else
    if [ -d "/Applications/Brave Browser.app" ]; then
      browser="brave"
      # -g: 不把 Brave 提到前台；profile 按需改，默认 Default
      open -g -a "Brave Browser" --args --profile-directory="Default" >/dev/null 2>&1 || true
      for _ in $(seq 1 10); do
        sleep 1
        doc="$(opencli doctor 2>/dev/null || true)"
        if printf '%s' "$doc" | grep -q '"extensionConnected":true'; then
          opencli_status="ok"
          break
        fi
      done
    fi
  fi
fi

if command -v agent-reach >/dev/null 2>&1; then
  if agent-reach channels >/dev/null 2>&1; then
    agent_reach_status="ok"
  else
    agent_reach_status="degraded"
  fi
fi

printf '{"opencli":"%s","agent_reach":"%s","browser":"%s"}\n' \
  "$opencli_status" "$agent_reach_status" "$browser"

if [ "$opencli_status" = "missing" ]; then
  echo "hint: 未找到 opencli，先安装：npm install -g @jackwener/opencli" >&2
elif [ "$opencli_status" != "ok" ]; then
  echo "hint: opencli 扩展未连接。确认 Brave 已装 OpenCLI 扩展并在 chrome://extensions 启用；多 profile 时把 --profile-directory 改成扩展所在的那个。" >&2
fi
if [ "$agent_reach_status" = "ok" ]; then
  if agent-reach doctor --text 2>/dev/null | grep -q "not_added    xiaohongshu"; then
    echo "hint: 小红书渠道未添加，需要时跑 agent-reach add xiaohongshu" >&2
  fi
fi
