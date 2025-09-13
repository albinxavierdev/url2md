# PowerShell Script for Advanced Media Processing
# Companion to url2md.bat for comprehensive media handling

param(
    [Parameter(Mandatory=$true)]
    [string]$MarkdownFile,
    
    [Parameter(Mandatory=$true)]
    [string]$BaseUrl,
    
    [string]$MediaDir = "media",
    
    [string]$MediaTypes = "images,videos,audio,documents,fonts",
    
    [switch]$SkipMedia
)

# Media file extensions
$ImageExtensions = @("jpg", "jpeg", "png", "gif", "webp", "svg", "bmp", "ico", "tiff", "tif")
$VideoExtensions = @("mp4", "webm", "ogg", "avi", "mov", "wmv", "flv", "mkv", "m4v")
$AudioExtensions = @("mp3", "wav", "ogg", "flac", "aac", "m4a", "wma", "opus")
$DocumentExtensions = @("pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx", "zip", "rar", "7z", "tar", "gz")
$FontExtensions = @("woff", "woff2", "ttf", "otf", "eot")

# Function to get media type from extension
function Get-MediaType {
    param([string]$Url)
    
    $extension = [System.IO.Path]::GetExtension($Url).TrimStart('.').ToLower()
    
    if ($ImageExtensions -contains $extension) { return "images" }
    if ($VideoExtensions -contains $extension) { return "videos" }
    if ($AudioExtensions -contains $extension) { return "audio" }
    if ($DocumentExtensions -contains $extension) { return "documents" }
    if ($FontExtensions -contains $extension) { return "fonts" }
    
    return "other"
}

# Function to resolve relative URLs
function Resolve-Url {
    param([string]$BaseUrl, [string]$RelativeUrl)
    
    if ($RelativeUrl -match "^https?://") {
        return $RelativeUrl
    }
    
    if ($RelativeUrl.StartsWith("//")) {
        $protocol = ([System.Uri]$BaseUrl).Scheme
        return "$protocol`:$RelativeUrl"
    }
    
    if ($RelativeUrl.StartsWith("/")) {
        $baseUri = [System.Uri]$BaseUrl
        return "$($baseUri.Scheme)://$($baseUri.Host)$RelativeUrl"
    }
    
    # Relative to current path
    $baseUri = [System.Uri]$BaseUrl
    $basePath = $baseUri.AbsoluteUri.Substring(0, $baseUri.AbsoluteUri.LastIndexOf('/') + 1)
    return "$basePath$RelativeUrl"
}

# Function to download media file
function Download-MediaFile {
    param([string]$Url, [string]$LocalPath, [string]$MediaType)
    
    $maxRetries = 3
    $timeout = 30
    
    if ($MediaType -eq "videos") { $timeout = 60 }
    if ($MediaType -eq "documents") { $timeout = 45 }
    
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Write-Host "  📥 Downloading $MediaType`: $Url" -ForegroundColor Yellow
            
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (compatible; URL2MD-Converter)")
            $webClient.DownloadFile($Url, $LocalPath)
            
            if (Test-Path $LocalPath -and (Get-Item $LocalPath).Length -gt 0) {
                $size = Get-Item $LocalPath | ForEach-Object { "{0:N2} KB" -f ($_.Length / 1KB) }
                Write-Host "  ✅ Downloaded: $(Split-Path $LocalPath -Leaf) ($size)" -ForegroundColor Green
                return $true
            }
            else {
                Remove-Item $LocalPath -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Host "  ⚠️  Attempt $i failed: $($_.Exception.Message)" -ForegroundColor Yellow
            if ($i -eq $maxRetries) {
                Write-Host "  ❌ Failed to download after $maxRetries attempts" -ForegroundColor Red
            }
        }
    }
    
    return $false
}

# Main processing function
function Process-MediaFiles {
    if ($SkipMedia) {
        Write-Host "Skipping media processing" -ForegroundColor Yellow
        return
    }
    
    if (-not (Test-Path $MarkdownFile)) {
        Write-Error "Markdown file not found: $MarkdownFile"
        return
    }
    
    Write-Host "🔍 Processing media files in: $MarkdownFile" -ForegroundColor Cyan
    
    $content = Get-Content $MarkdownFile -Raw
    $mediaUrls = @()
    
    # Extract markdown image URLs: ![alt](url)
    $imageMatches = [regex]::Matches($content, '!\[[^\]]*\]\(([^)]+)\)')
    foreach ($match in $imageMatches) {
        $mediaUrls += $match.Groups[1].Value
    }
    
    # Extract HTML img tags: <img src="url">
    $imgMatches = [regex]::Matches($content, '<img[^>]+src=["\']([^"\']+)["\']')
    foreach ($match in $imgMatches) {
        $mediaUrls += $match.Groups[1].Value
    }
    
    # Extract HTML video/audio tags
    $videoMatches = [regex]::Matches($content, '<(?:video|audio|source)[^>]+src=["\']([^"\']+)["\']')
    foreach ($match in $videoMatches) {
        $mediaUrls += $match.Groups[1].Value
    }
    
    # Extract document links
    $docMatches = [regex]::Matches($content, '<a[^>]+href=["\']([^"\']+\.(?:pdf|doc|docx|ppt|pptx|xls|xlsx|zip|rar|7z|tar|gz))["\']')
    foreach ($match in $docMatches) {
        $mediaUrls += $match.Groups[1].Value
    }
    
    # Extract CSS font URLs
    $fontMatches = [regex]::Matches($content, 'url\(([^)]*\.(?:woff2?|ttf|otf|eot)[^)]*)\)')
    foreach ($match in $fontMatches) {
        $url = $match.Groups[1].Value -replace '["\']', ''
        $mediaUrls += $url
    }
    
    $uniqueUrls = $mediaUrls | Sort-Object | Get-Unique
    $processedCount = 0
    $allowedTypes = $MediaTypes -split ','
    
    foreach ($mediaUrl in $uniqueUrls) {
        if ([string]::IsNullOrWhiteSpace($mediaUrl)) { continue }
        if ($mediaUrl.StartsWith("data:") -or $mediaUrl.StartsWith("#")) { continue }
        
        # Resolve relative URLs
        $resolvedUrl = Resolve-Url -BaseUrl $BaseUrl -RelativeUrl $mediaUrl
        $mediaType = Get-MediaType -Url $resolvedUrl
        
        # Check if this media type should be downloaded
        if ($allowedTypes -notcontains $mediaType) { continue }
        
        # Create media subdirectory
        $mediaSubDir = Join-Path $MediaDir $mediaType
        if (-not (Test-Path $mediaSubDir)) {
            New-Item -ItemType Directory -Path $mediaSubDir -Force | Out-Null
        }
        
        # Generate local filename
        $fileName = Split-Path $resolvedUrl -Leaf
        if ([string]::IsNullOrWhiteSpace([System.IO.Path]::GetExtension($fileName))) {
            $fileName += ".bin"
        }
        
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($MarkdownFile)
        $cleanFileName = $fileName -replace '[^\w\.-]', '_'
        $localFileName = "${baseName}_$cleanFileName"
        $localPath = Join-Path $mediaSubDir $localFileName
        
        # Skip if already downloaded
        if (Test-Path $localPath) {
            $size = Get-Item $localPath | ForEach-Object { "{0:N2} KB" -f ($_.Length / 1KB) }
            Write-Host "  ♻️  Using cached: $localFileName ($size)" -ForegroundColor Blue
            
            # Update content with local path
            $relativePath = "$mediaType/$localFileName" -replace '\\', '/'
            $content = $content -replace [regex]::Escape($mediaUrl), $relativePath
            $content = $content -replace [regex]::Escape($resolvedUrl), $relativePath
            $processedCount++
            continue
        }
        
        # Download the file
        if (Download-MediaFile -Url $resolvedUrl -LocalPath $localPath -MediaType $mediaType) {
            # Update content with local path
            $relativePath = "$mediaType/$localFileName" -replace '\\', '/'
            $content = $content -replace [regex]::Escape($mediaUrl), $relativePath
            $content = $content -replace [regex]::Escape($resolvedUrl), $relativePath
            $processedCount++
        }
    }
    
    # Write updated content back to file
    $content | Set-Content $MarkdownFile -Encoding UTF8
    
    Write-Host "✅ Processed $processedCount media files" -ForegroundColor Green
}

# Execute main function
Process-MediaFiles