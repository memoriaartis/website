param([switch]$Production, [string]$OutputDirectory = '', [string]$Locale = 'fr')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (!$OutputDirectory) { $OutputDirectory = $root }
$output = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $output -Force | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false)
function Read-Json($path) { Get-Content -LiteralPath (Join-Path $root $path) -Raw -Encoding UTF8 | ConvertFrom-Json }
function Escape($value) { [Net.WebUtility]::HtmlEncode([string]$value) }
function Write-File($path, $body) {
  $target = Join-Path $output $path
  New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
  [IO.File]::WriteAllText($target, $body, $utf8)
}
$config = Read-Json 'site.config.json'
$routeMap = Read-Json 'content/routes.json'
$routes = $routeMap.$Locale
if (!$routes) { throw "Unknown locale: $Locale" }
$ui = Read-Json "content/ui.$Locale.json"
$metadata = Read-Json "content/metadata.$Locale.json"
$images = Read-Json 'content/images.json'
$origin = $config.origin.TrimEnd('/')
if ($config.contactEmail -and ($config.contactEmail -notmatch '^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$' -or $config.contactEmail -match '[\r\n]')) { throw 'Contact email is invalid.' }
if ($origin -and $origin -notmatch '^https://[^/\s?#]+$') { throw 'Origin must be an HTTPS origin without a path.' }
if ($Production) {
  foreach ($key in @('origin','contactEmail','publisherName','publisherAddress','hostingName','hostingContact')) {
    if (![string]$config.$key) { throw "Public build blocked: configure $key in site.config.json." }
  }
  if (!$config.privacyApproved) { throw 'Public build blocked: complete content/privacy.fr.md for the actual setup and approve privacyApproved.' }
}
function Image-Area($id, $class = '') {
  $record = $images.$id
  if (!$record.src) { return "<div class='image-area $class' aria-hidden='true'></div>" }
  foreach ($field in @('source','permission','credit','width','height')) {
    if (!$record.$field) { throw "Image $id requires $field." }
  }
  if ($null -eq $record.alt) { throw "Image $id requires reviewed alt text (empty for decorative imagery)." }
  if ($record.src -notmatch '^/assets/[a-zA-Z0-9/_.-]+$' -or $record.src.Contains('..')) { throw 'Images must be local assets.' }
  if (!(Test-Path -LiteralPath (Join-Path $root $record.src.TrimStart('/')))) { throw "Missing image: $($record.src)" }
  if ($record.focalPoint -notmatch '^\d{1,3}% \d{1,3}%$') { throw 'Image focalPoint must contain two percentages.' }
  $loading = if ($id -eq 'hero') { "fetchpriority='high'" } else { "loading='lazy'" }
  return "<figure><div class='image-area has-image $class'><img src='$(Escape $record.src)' alt='$(Escape $record.alt)' width='$($record.width)' height='$($record.height)' style='object-position:$($record.focalPoint)' $loading></div><figcaption class='image-credit'>$(Escape $record.credit)</figcaption></figure>"
}
function Render-Link($text, $kind) {
  $parts = $text -split (' ' + [char]0x2192 + ' '), 2
  if ($parts.Length -ne 2) { throw "Link requires label and destination: $text" }
  $href = $parts[1].Trim([char]96)
  if ($href -notmatch ('^/' + [regex]::Escape($Locale) + '/')) { throw "Unsupported internal link $href" }
  $class = if ($kind -eq 'Text link') { 'text-link' } elseif ($kind -eq 'Secondary CTA') { 'text-link' } else { 'button primary' }
  return "<a class='$class' href='$(Escape $href)'>$(Escape $parts[0])</a>"
}
function Render-Copy($text) {
  $html = [Collections.Generic.List[string]]::new()
  $blocks = [regex]::Split($text.Trim(), '\r?\n\s*\r?\n')
  foreach ($block in $blocks) {
    $block = $block.Trim()
    if (!$block) { continue }
    if ($block -match '^\*\*(Eyebrow|H1|H2|Introduction|Primary CTA|Secondary CTA|CTA|Text link):\*\*\s*(.+)$') {
      $kind = $Matches[1]; $value = $Matches[2]
      switch ($kind) {
        'Eyebrow' { $html.Add("<p class='eyebrow'>$(Escape $value)</p>") }
        'H1' { $html.Add("<h1>$(Escape $value)</h1>") }
        'H2' { $html.Add("<h2>$(Escape $value)</h2>") }
        'Introduction' { $html.Add("<p class='intro'>$(Escape $value)</p>") }
        default { $html.Add((Render-Link $value $kind)) }
      }
    } elseif ($block -match '^\*\*(.+?)\*\*$') { $html.Add("<h3>$(Escape $Matches[1])</h3>") }
    elseif ($block -match '^## (.+)$') { $html.Add("<h2>$(Escape $Matches[1])</h2>") }
    else { $html.Add("<p>$(Escape ($block -replace '\r?\n', ' '))</p>") }
  }
  return $html -join "`n"
}
function Page-Sections($id) {
  $source = Get-Content -LiteralPath (Join-Path $root "content/$id.$Locale.md") -Raw -Encoding UTF8
  return @([regex]::Split($source, '(?m)^### .+\r?\n') | Where-Object { $_.Trim() })
}
function Split-Section($body, $number = '') {
  $match = [regex]::Match($body, '(?m)^\*\*H2:\*\* (.+)\r?\n')
  if (!$match.Success) { throw 'Section needs H2.' }
  $heading = Escape $match.Groups[1].Value
  $copy = Render-Copy $body.Substring($match.Index + $match.Length)
  $prefix = if ($number) { "<span class='section-number'>$number</span>" } else { '' }
  return "<section class='section split'><h2>$prefix$heading</h2><div class='section-copy'>$copy</div></section>"
}
function Invitation($body) {
  $match = [regex]::Match($body, '(?m)^\*\*H2:\*\* (.+)\r?\n')
  return "<section class='invitation'><h2>$(Escape $match.Groups[1].Value)</h2><div>$(Render-Copy $body.Substring($match.Index + $match.Length))</div></section>"
}
function Contact-Preview {
  $f = $ui.form
  $subjectOptions = "<option value=''>$(Escape $f.subjectPlaceholder)</option>"
  foreach ($subject in $f.subjects.PSObject.Properties) { $subjectOptions += "<option value='$($subject.Name)'>$(Escape $subject.Value)</option>" }
  return @"
<div><p class='notice' id='contact-notice'>$(Escape $ui.preview)</p>
<form aria-describedby='contact-notice' onsubmit='return false' data-required='$(Escape $f.required)' data-email-error='$(Escape $f.invalidEmail)' data-subject-error='$(Escape $f.invalidSubject)' data-length-error='$(Escape $f.tooLong)'>
<div class='field'><label for='name'>$(Escape $f.name)</label><input id='name' name='name' autocomplete='name' maxlength='120' required></div>
<div class='field'><label for='email'>$(Escape $f.email)</label><input id='email' name='email' type='email' autocomplete='email' maxlength='254' required></div>
<div class='field'><label for='organisation'>$(Escape $f.organisation) <small>($(Escape $f.optional))</small></label><input id='organisation' name='organisation' autocomplete='organization' maxlength='180'></div>
<div class='field'><label for='subject'>$(Escape $f.subject)</label><select id='subject' name='subject' required>$subjectOptions</select></div>
<div class='field'><label for='message'>$(Escape $f.message)</label><textarea id='message' name='message' maxlength='6000' aria-describedby='message-help' required></textarea><p class='helper' id='message-help'>$(Escape $f.helper)</p></div>
<p class='privacy-copy'>$(Escape $f.privacy) <a href='$($routes.privacy)'>$(Escape $ui.nav.privacy)</a>.</p>
<button class='button primary' type='submit' disabled>$(Escape $f.submit)</button><p role='status' aria-live='polite'></p>
</form></div>
"@
}
function Page-Body($id) {
  if ($id -in @('legal','privacy')) {
    $copy = Get-Content -LiteralPath (Join-Path $root "content/$id.$Locale.md") -Raw -Encoding UTF8
    $notice = if ($id -eq 'legal') { $ui.legalPreview } else { $ui.privacyPreview }
    $details = ''
    if ($id -eq 'legal' -and $config.publisherName) {
      $details = "<h2>$(Escape $ui.publisherLabel)</h2><p>$(Escape $ui.name)<br>$(Escape $config.publisherName)<br>$(Escape $config.publisherAddress)</p><h2>$(Escape $ui.hostingLabel)</h2><p>$(Escape $config.hostingName)<br>$(Escape $config.hostingContact)</p>"
    }
    $warning = if (!$Production) { "<p class='notice'>$(Escape $notice)</p>" } else { '' }
    $email = if ($config.contactEmail) { "<p><a href='mailto:$(Escape $config.contactEmail)'>$(Escape $config.contactEmail)</a></p>" } else { '' }
    return "<div class='page-intro'><h1>$(Escape $ui.nav.$id)</h1></div><div class='legal-content'>$warning$details$(Render-Copy $copy)$email</div>"
  }
  $sections = Page-Sections $id
  if ($id -eq 'home') {
    $hero = Render-Copy $sections[0]
    # Wrap the two hero links together without putting editorial text in templates.
    $hero = $hero -replace '(<a class=.button primary.)', '<div class="actions">$1'
    $hero += '</div>'
    $approach = $sections[2]
    $heading = [regex]::Match($approach, '(?m)^\*\*H2:\*\* (.+)').Groups[1].Value.Trim()
    $columns = ''
    $matches = [regex]::Matches($approach, '(?ms)^\*\*([^*:]+)\*\*\s*\r?\n\s*(.+?)(?=\r?\n\s*\*\*|\z)')
    $i = 0
    foreach ($item in $matches) { $i++; $columns += "<article><span class='section-number'>0$i</span><h3>$(Escape $item.Groups[1].Value)</h3>$(Render-Copy $item.Groups[2].Value)</article>" }
    $link = [regex]::Match($approach, '(?m)^\*\*Text link:\*\* (.+)').Groups[1].Value.Trim()
    return "<section class='hero'><div class='hero-copy'>$hero</div>$(Image-Area 'hero')</section>$(Split-Section $sections[1] '01')<section class='section'><h2>$(Escape $heading)</h2><div class='columns'>$columns</div>$(Render-Link $link 'Text link')</section>$(Split-Section $sections[3] '03')$(Invitation $sections[4])"
  }
  $intro = "<div class='page-intro'>$(Render-Copy $sections[0])</div>"
  if ($id -eq 'contact') {
    $entries = ''
    foreach ($match in [regex]::Matches($sections[1], '(?ms)^\*\*(.+?)\*\*\s*\r?\n\s*(.+?)(?=\r?\n\s*\*\*|\z)')) {
      $entries += "<article><h2>$(Escape $match.Groups[1].Value)</h2>$(Render-Copy $match.Groups[2].Value)</article>"
    }
    $contact = if ($config.contactEmail) { "<div><p>$(Escape $ui.directEmail)</p><a class='button primary' href='mailto:$(Escape $config.contactEmail)'>$(Escape $config.contactEmail)</a></div>" } else { Contact-Preview }
    return "$intro<div class='contact-layout'><div class='contact-entries'>$entries</div>$contact</div>"
  }
  $body = "$intro$(Image-Area $id 'wide-image')<div class='editorial'>"
  for ($index = 1; $index -lt ($sections.Count - 1); $index++) {
    if ($id -eq 'approach' -and $index -eq 1) {
      $heading = [regex]::Match($sections[$index], '(?m)^\*\*H2:\*\* (.+)').Groups[1].Value.Trim()
      $steps = ''
      foreach ($step in [regex]::Matches($sections[$index], '(?ms)^\*\*\d\. (.+?)\*\*\s*\r?\n\s*(.+?)(?=\r?\n\s*\*\*|\z)')) {
        $steps += "<li><div><h3>$(Escape $step.Groups[1].Value)</h3>$(Render-Copy $step.Groups[2].Value)</div></li>"
      }
      $body += "<section class='section split'><h2>$(Escape $heading)</h2><ol class='steps'>$steps</ol></section>"
    } else { $body += Split-Section $sections[$index] }
  }
  return "$body</div>$(Invitation $sections[-1])"
}
foreach ($page in $routes.PSObject.Properties) {
  $id = $page.Name
  $nav = ''
  foreach ($key in @('home','project','approach','contact')) {
    $current = if ($key -eq $id) { " aria-current='page'" } else { '' }
    $class = if ($key -eq 'home') { 'mobile-home' } elseif ($key -eq 'contact') { 'contact-link' } else { '' }
    $nav += "<a class='$class' href='$($routes.$key)'$current>$(Escape $ui.nav.$key)</a>"
  }
  $footer = ''
  foreach ($key in @('project','approach','contact','legal','privacy')) { $footer += "<a href='$($routes.$key)'>$(Escape $ui.nav.$key)</a>" }
  $meta = $metadata.$id
  $canonical = if ($origin) { "<link rel='canonical' href='$(Escape ($origin + $page.Value))'>" } else { '' }
  $robots = if ($Production) { 'index, follow' } else { 'noindex, nofollow' }
  $body = Page-Body $id
  Write-File ($page.Value.TrimStart('/') + 'index.html') @"
<!doctype html>
<html lang='$(Escape $ui.lang)'>
<head><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'><meta name='theme-color' content='#f5f2eb'><meta name='robots' content='$robots'><title>$(Escape $meta.title)</title><meta name='description' content='$(Escape $meta.description)'>$canonical<link rel='stylesheet' href='/assets/site.css'><script defer src='/assets/site.js'></script></head>
<body><a class='skip' href='#contenu'>$(Escape $ui.skip)</a>
<header class='site-header'><div class='wrap header-inner'><a class='wordmark' href='$($routes.home)'>$(Escape $ui.name)</a><button class='menu-button' type='button' aria-controls='navigation' aria-expanded='false' data-menu-toggle data-open='$(Escape $ui.menu)' data-close='$(Escape $ui.closeMenu)'>$(Escape $ui.menu)</button><nav class='navigation' id='navigation' aria-label='$(Escape $ui.navigationLabel)' data-menu>$nav</nav></div></header>
<main class='wrap' id='contenu' tabindex='-1'>$body</main>
<footer class='site-footer'><div class='wrap'><div class='footer-top'><div class='footer-brand'><a class='wordmark' href='$($routes.home)'>$(Escape $ui.name)</a><p>$(Escape $ui.footerDescription)</p></div><nav class='footer-links' aria-label='$(Escape $ui.footerNavigationLabel)'>$footer</nav></div><div class='copyright'>&copy; $((Get-Date).Year) $(Escape $ui.name)</div></div></footer></body></html>
"@
}
Write-File 'index.html' "<!doctype html><html lang='fr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'><meta name='robots' content='noindex'><meta http-equiv='refresh' content='0;url=/fr/'><title>$(Escape $ui.name)</title></head><body><a href='/fr/'>$(Escape $ui.nav.home) &mdash; $(Escape $ui.name)</a></body></html>"
if ($output -ne $root) { Copy-Item -LiteralPath (Join-Path $root 'assets') -Destination $output -Recurse -Force }
if ($Production) {
  $urls = ($routeMap.PSObject.Properties | ForEach-Object { $_.Value.PSObject.Properties } | ForEach-Object { "<url><loc>$(Escape ($origin + $_.Value))</loc></url>" }) -join ''
  Write-File 'sitemap.xml' "<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>$urls</urlset>"
  Write-File 'robots.txt' "User-agent: *`nAllow: /`nSitemap: $origin/sitemap.xml`n"
} else {
  Write-File 'robots.txt' "User-agent: *`nDisallow: /`n"
  # An empty preview sitemap never advertises unapproved public pages.
  Write-File 'sitemap.xml' "<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'></urlset>"
}
Write-Output "Built 6 $Locale pages in $output (production: $([bool]$Production))."
