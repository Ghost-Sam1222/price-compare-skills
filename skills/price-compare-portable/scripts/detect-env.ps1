# 探测 Windows 的比价环境，输出一行 JSON。
# 用法: powershell -ExecutionPolicy Bypass -File scripts/detect-env.ps1

$ErrorActionPreference = "SilentlyContinue"

$os = "windows"
$browsers = @()

$paths = [ordered]@{
  "Chrome"   = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")
  "Edge"     = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")
  "Brave"    = @("$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe", "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe")
  "Chromium" = @("$env:LOCALAPPDATA\Chromium\Application\chrome.exe", "$env:ProgramFiles\Chromium\Application\chrome.exe")
  "360极速"  = @("$env:LOCALAPPDATA\360Chrome\Chrome\Application\360chrome.exe", "${env:ProgramFiles(x86)}\360Chrome\Chrome\Application\360chrome.exe")
  "QQ浏览器" = @("${env:ProgramFiles(x86)}\Tencent\QQBrowser\QQBrowser.exe", "$env:LOCALAPPDATA\Tencent\QQBrowser\Application\QQBrowser.exe")
  "搜狗"     = @("${env:ProgramFiles(x86)}\SogouExplorer\SogouExplorer.exe", "$env:LOCALAPPDATA\SogouExplorer\SogouExplorer.exe")
}
foreach ($k in $paths.Keys) {
  foreach ($p in $paths[$k]) {
    if (Test-Path $p) { $browsers += $k; break }
  }
}

$opencli = "missing"
$extension = "unknown"
if (Get-Command opencli -ErrorAction SilentlyContinue) {
  $opencli = "ok"
  $doc = (& opencli doctor 2>$null | Out-String)
  if ($doc -match '"extensionConnected":true') {
    $extension = "connected"
  } else {
    $extension = "disconnected"
  }
}

$agentReach = "missing"
if (Get-Command agent-reach -ErrorAction SilentlyContinue) {
  & agent-reach channels *> $null
  if ($LASTEXITCODE -eq 0) { $agentReach = "ok" } else { $agentReach = "degraded" }
}

[ordered]@{
  os          = $os
  browsers    = $browsers
  opencli     = $opencli
  extension   = $extension
  agent_reach = $agentReach
} | ConvertTo-Json -Compress
