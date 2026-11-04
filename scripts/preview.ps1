param([int]$Port = 8080)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "Preview: http://localhost:$Port/fr/ (Ctrl+C to stop)"
try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    $client.ReceiveTimeout = 3000
    $stream = $client.GetStream()
    try {
      $reader = [IO.StreamReader]::new($stream)
      $request = $reader.ReadLine()
      if ($request -notmatch '^GET (/[^ ]*) HTTP/1\.[01]$') { throw 'Not found' }
      $requestPath = $Matches[1]
      $path = [Uri]::UnescapeDataString(($requestPath -split '\?')[0])
      if (($path -split '/') -contains '..' -or ($path -split '/') -contains '.') { throw 'Not found' }
      while ($reader.ReadLine()) { }
      # Serve generated pages and public assets only, never sources/configuration.
      if ($path -notmatch '^/(fr(/.*)?|assets/[a-zA-Z0-9/_.-]+|index\.html|robots\.txt|sitemap\.xml)?$') { throw 'Not found' }
      if ($path.EndsWith('/')) { $path += 'index.html' }
      $target = [IO.Path]::GetFullPath((Join-Path $root $path.TrimStart('/')))
      if (!$target.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Not found' }
      if (!(Test-Path -LiteralPath $target -PathType Leaf)) { throw 'Not found' }
      $contentType = switch ([IO.Path]::GetExtension($target)) {
        '.html' { 'text/html; charset=utf-8' }
        '.css' { 'text/css; charset=utf-8' }
        '.js' { 'text/javascript; charset=utf-8' }
        '.xml' { 'application/xml; charset=utf-8' }
        '.jpg' { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.png' { 'image/png' }
        '.webp' { 'image/webp' }
        '.avif' { 'image/avif' }
        default { 'text/plain; charset=utf-8' }
      }
      $bytes = [IO.File]::ReadAllBytes($target)
      $headers = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`nX-Content-Type-Options: nosniff`r`n`r`n")
      $stream.Write($headers, 0, $headers.Length)
      $stream.Write($bytes, 0, $bytes.Length)
    } catch {
      $headers = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 404 Not Found`r`nContent-Length: 0`r`nConnection: close`r`n`r`n")
      $stream.Write($headers, 0, $headers.Length)
    }
    finally { $client.Close() }
  }
} finally { $listener.Stop() }
