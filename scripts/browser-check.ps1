param([string]$PreviewUrl = 'http://localhost:8080', [int]$DebugPort = 9222)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$artifacts = Join-Path $root '.preview'
New-Item -ItemType Directory -Force -Path "$artifacts/screens" | Out-Null
$edge = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
if (!(Test-Path -LiteralPath $edge)) { throw 'Microsoft Edge is required for this optional browser check.' }
$arguments = @('--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check','--disable-background-networking',"--remote-debugging-port=$DebugPort","--remote-allow-origins=http://localhost:$DebugPort",('--user-data-dir="' + $artifacts + '/edge-check-profile"'),'about:blank')
$process = Start-Process -FilePath $edge -ArgumentList $arguments -WindowStyle Hidden -PassThru
$client = New-Object Net.WebClient
$socket = [Net.WebSockets.ClientWebSocket]::new()
$socket.Options.SetRequestHeader('Origin',"http://localhost:$DebugPort")
$script:cdpId = 0
$script:browserErrors = [Collections.Generic.List[string]]::new()
function Assert($condition, $message) { if (!$condition) { throw $message } }
function Cdp($method, $parameters = @{}) {
  $script:cdpId++
  $requestId = $script:cdpId
  $cancel = [Threading.CancellationTokenSource]::new(30000)
  try {
    $json = @{id=$requestId;method=$method;params=$parameters} | ConvertTo-Json -Depth 30 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $socket.SendAsync([ArraySegment[byte]]::new($bytes), [Net.WebSockets.WebSocketMessageType]::Text, $true, $cancel.Token).GetAwaiter().GetResult() | Out-Null
    while ($true) {
      $message = [IO.MemoryStream]::new()
      try {
        do {
          $buffer = New-Object byte[] 65536
          $chunk = $socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), $cancel.Token).GetAwaiter().GetResult()
          if ($chunk.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close) { throw 'Browser socket closed.' }
          $message.Write($buffer, 0, $chunk.Count)
        } while (!$chunk.EndOfMessage)
        $response = [Text.Encoding]::UTF8.GetString($message.ToArray()) | ConvertFrom-Json
      } finally { $message.Dispose() }
      if ($response.method -eq 'Runtime.exceptionThrown') { $script:browserErrors.Add(($response.params | ConvertTo-Json -Depth 10 -Compress)) }
      if ($response.method -eq 'Log.entryAdded' -and $response.params.entry.level -eq 'error' -and $response.params.entry.url -notmatch 'favicon') { $script:browserErrors.Add($response.params.entry.text) }
      if ($response.id -eq $requestId) {
        if ($response.error) { throw ($response.error | ConvertTo-Json -Compress) }
        return $response.result
      }
    }
  } finally { $cancel.Dispose() }
}
function Evaluate($expression) {
  $result = Cdp 'Runtime.evaluate' @{expression=$expression;returnByValue=$true;awaitPromise=$true}
  if ($result.exceptionDetails) { throw ($result.exceptionDetails | ConvertTo-Json -Depth 10 -Compress) }
  return $result.result.value
}
function Visit($path) {
  Cdp 'Page.navigate' @{url=($PreviewUrl.TrimEnd('/') + $path)} | Out-Null
  for ($attempt=0; $attempt -lt 40; $attempt++) {
    Start-Sleep -Milliseconds 100
    try { $ready = Evaluate '({url:location.pathname + location.search, ready:document.readyState})' } catch { continue }
    if ($ready.url -eq $path -and $ready.ready -eq 'complete') { return }
  }
  throw "Page did not load: $path"
}
function Key($key, $code, $virtualKey, $modifiers = 0) {
  $down = @{type='rawKeyDown';key=$key;code=$code;windowsVirtualKeyCode=$virtualKey;modifiers=$modifiers}
  if ($key -eq 'Enter') { $down.type = 'keyDown'; $down.text = "`r"; $down.unmodifiedText = "`r" }
  Cdp 'Input.dispatchKeyEvent' $down | Out-Null
  Cdp 'Input.dispatchKeyEvent' @{type='keyUp';key=$key;code=$code;windowsVirtualKeyCode=$virtualKey;modifiers=$modifiers} | Out-Null
}
function Screenshot($name) {
  $result = Cdp 'Page.captureScreenshot' @{format='png';captureBeyondViewport=$false}
  [IO.File]::WriteAllBytes((Join-Path $artifacts "screens/$name.png"), [Convert]::FromBase64String($result.data))
}
try {
  $tabs = $null
  for ($attempt=0; $attempt -lt 50; $attempt++) {
    try { $tabs = $client.DownloadString("http://localhost:$DebugPort/json/list") | ConvertFrom-Json; if ($tabs) { break } } catch { Start-Sleep -Milliseconds 200 }
  }
  Assert $tabs 'Edge debugging endpoint did not start.'
  $tab = @($tabs | Where-Object type -eq 'page')[0]
  $socket.ConnectAsync([Uri]$tab.webSocketDebuggerUrl,[Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
  Cdp 'Page.enable' | Out-Null
  Cdp 'Runtime.enable' | Out-Null
  Cdp 'Log.enable' | Out-Null
  $pages = @('/website/fr/','/website/fr/le-projet/','/website/fr/notre-demarche/','/website/fr/contact/','/website/fr/mentions-legales/','/website/fr/confidentialite/')
  foreach ($width in @(360,390,768,1440)) {
    Cdp 'Emulation.setDeviceMetricsOverride' @{width=$width;height=1000;deviceScaleFactor=1;mobile=$false} | Out-Null
    foreach ($path in $pages) {
      Visit $path
      $state = Evaluate '({width:innerWidth, content:document.documentElement.scrollWidth, h1:document.querySelectorAll("h1").length, broken:[...document.images].filter(i=>!i.complete||!i.naturalWidth).length})'
      Assert ($state.content -le $state.width + 1) "Horizontal overflow at ${width}px: $path ($($state.content))"
      Assert ($state.h1 -eq 1) "Heading issue: $path"
      Assert ($state.broken -eq 0) "Broken image: $path"
      if ($path -eq '/website/fr/') { Screenshot "home-$width" }
      if ($path -eq '/website/fr/notre-demarche/' -and $width -in @(390,1440)) {
        Evaluate 'document.querySelector(".knowledge-example").scrollIntoView(); true' | Out-Null
        Screenshot "example-$width"
      }
    }
    Write-Output "Browser: 6 pages at ${width}px, no horizontal overflow or broken images."
  }
  Cdp 'Emulation.setDeviceMetricsOverride' @{width=390;height=900;deviceScaleFactor=1;mobile=$false} | Out-Null
  Visit '/website/fr/'
  Key 'Tab' 'Tab' 9
  $focus = Evaluate '({skip:document.activeElement.classList.contains("skip"), outline:getComputedStyle(document.activeElement).outlineWidth})'
  Assert ($focus.skip -and $focus.outline -eq '3px') 'Skip link or keyboard focus is not visible.'
  Evaluate 'document.querySelector("[data-menu-toggle]").focus(); true' | Out-Null
  Key 'Enter' 'Enter' 13
  Assert (Evaluate 'document.querySelector("[data-menu-toggle]").getAttribute("aria-expanded") === "true"') 'Menu did not open from keyboard.'
  Key 'Tab' 'Tab' 9
  Assert (Evaluate 'document.activeElement.classList.contains("mobile-home")') 'First menu link is not next in the tab order.'
  Key 'Escape' 'Escape' 27
  Assert (Evaluate 'document.activeElement.matches("[data-menu-toggle]") && document.activeElement.getAttribute("aria-expanded") === "false"') 'Escape did not close menu and restore focus.'
  Write-Output 'Browser: skip link, visible focus, menu Enter/Tab/Escape passed.'
  foreach ($subject in @('savoir-faire','partenariat','soutien','unknown')) {
    Visit "/website/fr/contact/?sujet=$subject"
    $expected = if ($subject -eq 'unknown') { '' } else { $subject }
    $selected = Evaluate 'document.querySelector("[name=subject]")?.value'
    if ($null -ne $selected) { Assert ($selected -eq $expected) "Subject preselection failed: $subject" }
  }
  $hasForm = Evaluate 'Boolean(document.querySelector("form"))'
  if ($hasForm) {
    $formState = Evaluate @'
(() => {
 const email=document.querySelector('#email'); email.value='invalid'; email.dispatchEvent(new FocusEvent('blur'));
 const name=document.querySelector('#name'); name.value=''; name.dispatchEvent(new FocusEvent('blur'));
 const message=document.querySelector('#message'); message.value='Message de verification';
 document.querySelector('button[type=submit]').click();
 return {email:email.getAttribute('aria-invalid'),name:name.getAttribute('aria-invalid'),error:document.querySelector('#email-error').textContent,disabled:document.querySelector('button[type=submit]').disabled,retained:message.value==='Message de verification'};
})()
'@
    Assert ($formState.email -eq 'true' -and $formState.name -eq 'true' -and $formState.error -and $formState.disabled -and $formState.retained) 'Preview form validation or safety failed.'
  } else { Assert (Evaluate 'Boolean(document.querySelector("a[href^=\"mailto:\"]"))') 'No configured contact method found.' }
  Write-Output 'Browser: contact validation, retained content and subject query handling passed (delivery unconfigured).'
  Cdp 'Emulation.setScriptExecutionDisabled' @{value=$true} | Out-Null
  Visit '/website/fr/'
  $noJs = Evaluate '({h1:!!document.querySelector("h1"),nav:getComputedStyle(document.querySelector(".navigation")).display,menu:getComputedStyle(document.querySelector(".menu-button")).display})'
  Assert ($noJs.h1 -and $noJs.nav -ne 'none' -and $noJs.menu -eq 'none') 'No-JavaScript navigation/readability failed.'
  Cdp 'Emulation.setScriptExecutionDisabled' @{value=$false} | Out-Null
  Visit '/fr/'
  Cdp 'Page.navigate' @{url=($PreviewUrl.TrimEnd('/') + '/website/')} | Out-Null
  for ($attempt=0; $attempt -lt 40; $attempt++) {
    Start-Sleep -Milliseconds 100
    if (Evaluate 'location.pathname === "/website/fr/" && document.readyState === "complete"') { break }
  }
  Assert (Evaluate 'location.pathname === "/website/fr/"') 'Entry redirect lost the GitHub Pages mount.'
} finally {
  $socket.Dispose()
  $client.Dispose()
  if ($process -and !$process.HasExited) { Stop-Process -Id $process.Id -ErrorAction SilentlyContinue }
}
Assert ($script:browserErrors.Count -eq 0) ('Browser errors: ' + ($script:browserErrors -join '; '))
Write-Output 'Browser: no-JavaScript content, entry redirect and console checks passed. Screenshots: .preview/screens/'
