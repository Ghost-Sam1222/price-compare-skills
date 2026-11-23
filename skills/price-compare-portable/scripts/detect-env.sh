#!/usr/bin/env bash
# 探测 macOS / Linux 的比价环境，输出一行 JSON。
# 用法: bash scripts/detect-env.sh

set -uo pipefail

os="unknown"
case "$(uname -s)" in
  Darwin) os="macos" ;;
  Linux) os="linux" ;;
  *) os="$(uname -s | tr '[:upper:]' '[:lower:]')" ;;
esac

browsers=()
if [ "$os" = "macos" ]; then
  for app in "Google Chrome" "Brave Browser" "Microsoft Edge" "Chromium" "360Chrome" "QQBrowser"; do
    [ -d "/Applications/$app.app" ] && browsers+=("$app")
  done
elif [ "$os" = "linux" ]; then
  for bin in google-chrome google-chrome-stable chromium chromium-browser brave-browser microsoft-edge; do
    command -v "$bin" >/dev/null 2>&1 && browsers+=("$bin")
  done
fi

opencli_status="missing"
extension="unknown"
if command -v opencli >/dev/null 2>&1; then
  opencli_status="ok"
  doc="$(opencli doctor 2>/dev/null || true)"
  if printf '%s' "$doc" | grep -q '"extensionConnected":true'; then
    extension="connected"
  else
    extension="disconnected"
  fi
fi

agent_reach="missing"
if command -v agent-reach >/dev/null 2>&1; then
  if agent-reach channels >/dev/null 2>&1; then
    agent_reach="ok"
  else
    agent_reach="degraded"
  fi
fi

if [ "${#browsers[@]}" -eq 0 ]; then
  b="[]"
else
  b="["
  for x in "${browsers[@]}"; do b="$b\"$x\","; done
  b="${b%,}]"
fi

printf '{"os":"%s","browsers":%s,"opencli":"%s","extension":"%s","agent_reach":"%s"}\n' \
  "$os" "$b" "$opencli_status" "$extension" "$agent_reach"
