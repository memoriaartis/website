$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$routes = (Get-Content "$root/content/routes.json" -Raw -Encoding UTF8 | ConvertFrom-Json).fr
function Assert($condition, $message) { if (!$condition) { throw $message } }
$count = 0
foreach ($route in $routes.PSObject.Properties) {
  $file = Join-Path $root ($route.Value.TrimStart('/') + 'index.html')
  $html = [IO.File]::ReadAllText($file)
  Assert (($html | Select-String '<h1[ >]' -AllMatches).Matches.Count -eq 1) "One H1 required: $file"
  Assert ($html.Contains("lang='fr'")) "French language missing: $file"
  Assert ($html.Contains("content='noindex, nofollow'")) "Preview indexing protection missing: $file"
  Assert (!$html.Contains('Implementation note')) "Internal notes exposed: $file"
  Assert (!$html.Contains('Hello Gr')) "Old content remains: $file"
  foreach ($link in [regex]::Matches($html, '(?:href|src)=''([^'']+)''')) {
    $url = [Net.WebUtility]::HtmlDecode($link.Groups[1].Value)
    if ($url.StartsWith('#')) { Assert ($html.Contains("id='$($url.Substring(1))'")) "Missing anchor: $url"; continue }
    if ($url -match '^[a-z]+:' -or $url.StartsWith('//')) { continue }
    foreach ($mount in @('', '/website')) {
      $pageUrl = [Uri]('https://preview.invalid' + $mount + $route.Value)
      $resolved = [Uri]::new($pageUrl, $url)
      Assert ($resolved.AbsolutePath.StartsWith($mount + '/')) "Link escapes hosting mount: $url from $pageUrl"
      $path = $resolved.AbsolutePath.Substring($mount.Length)
      if ($path.EndsWith('/')) { $path += 'index.html' }
      Assert (Test-Path -LiteralPath (Join-Path $root $path.TrimStart('/')) -PathType Leaf) "Broken local URL: $url from $pageUrl"
    }
  }
  if ($route.Name -in @('home','project','approach','contact')) {
    $copy = [IO.File]::ReadAllText((Join-Path $root "content/$($route.Name).fr.md"))
    $rendered = [Net.WebUtility]::HtmlDecode(($html -replace '<[^>]+>', ' ')) -replace '\s+', ' '
    foreach ($line in ($copy -split '\r?\n')) {
      $line = $line.Trim()
      if (!$line -or $line.StartsWith('###')) { continue }
      $text = $line -replace '^\*\*(?:Eyebrow|H1|H2|Introduction|Primary CTA|Secondary CTA|Text link|CTA):\*\*\s*', ''
      $text = $text -replace '^\*\*\d\. ', '' -replace '^\*\*', '' -replace '\*\*$', ''
      $text = ($text -split (' ' + [char]0x2192 + ' '))[0]
      Assert ($rendered.Contains($text)) "Editorial copy missing on $($route.Name): $text"
    }
  }
  $count++
}
$homeHtml = [IO.File]::ReadAllText((Join-Path $root 'fr/index.html'))
Assert (([regex]::Matches($homeHtml, '<article>')).Count -eq 3) 'Home must have three approach columns.'
$approach = [IO.File]::ReadAllText((Join-Path $root 'fr/notre-demarche/index.html'))
Assert (([regex]::Matches($approach, '<li>')).Count -eq 4) 'Approach must have four steps.'
$contact = [IO.File]::ReadAllText((Join-Path $root 'fr/contact/index.html'))
Assert ($contact.Contains("type='submit' disabled")) 'Unconfigured contact must not accept submission.'
foreach ($subject in @('savoir-faire','partenariat','soutien','autre')) { Assert ($contact.Contains("value='$subject'")) "Missing subject: $subject" }
foreach ($field in @('name','email','organisation','subject','message')) { Assert ($contact.Contains("for='$field'")) "Missing label: $field" }
$entry = [IO.File]::ReadAllText((Join-Path $root 'index.html'))
$redirect = [regex]::Match($entry, 'url=([^''"]+)').Groups[1].Value
foreach ($mount in @('', '/website')) {
  $resolved = [Uri]::new([Uri]("https://preview.invalid$mount/"), $redirect)
  Assert ($resolved.AbsolutePath -eq "$mount/fr/") "Entry redirect escapes hosting mount: $resolved"
}
Write-Output "Passed: $count pages, links/assets at root and /website/, entry redirects, anchors, exact editorial copy, headings, contact labels and preview safety."
