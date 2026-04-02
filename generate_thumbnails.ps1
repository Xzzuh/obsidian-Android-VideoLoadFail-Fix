# generate_thumbnails.ps1 本文件必须为ANSI编码，不可UTF-8
# 用法: .\generate_thumbnails.ps1 -VaultRoot "D:\ObsidianVault" -FFmpegPath "C:\ffmpeg\bin\ffmpeg.exe" [-ThumbFolderName ".thumbnails"] [-ThumbExt "webp"]

param(
    [Parameter(Mandatory=$true)]
    [string]$VaultRoot,
    
    [Parameter(Mandatory=$true)]
    [string]$FFmpegPath,

    [Parameter(Mandatory=$false)]
    [string]$ThumbFolderName = ".thumbnails",

    [Parameter(Mandatory=$false)]
    [string]$ThumbExt = "webp"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

if (-not (Test-Path $VaultRoot)) {
    Write-Error "仓库目录不存在: $VaultRoot"
    exit 1
}
Set-Location $VaultRoot

if (-not (Test-Path $FFmpegPath)) {
    Write-Error "找不到 ffmpeg: $FFmpegPath"
    exit 1
}

# 规范化扩展名
$ext = $ThumbExt.Trim().TrimStart('.').ToLower()
if ($ext -eq '') { $ext = 'webp' }

# 根据扩展名设置 ffmpeg 编码器、质量参数和像素格式
$encParams = @()
$pixFmt = ''
switch ($ext) {
    'jpg' { 
        $encParams = @('-c:v', 'mjpeg', '-q:v', '2', '-color_range', '2')
        $pixFmt = 'yuv420p'
    }
    'jpeg' { 
        $encParams = @('-c:v', 'mjpeg', '-q:v', '2', '-color_range', '2')
        $pixFmt = 'yuv420p'
    }
    'png' { 
        $encParams = @('-c:v', 'png', '-compression_level', '6')
        $pixFmt = 'rgba'       # PNG 支持透明通道
    }
    'webp' { 
        $encParams = @('-c:v', 'libwebp', '-q:v', '80')
        $pixFmt = 'yuva420p'   # WebP 支持透明
    }
    'bmp' { 
        $encParams = @('-c:v', 'bmp')
        $pixFmt = 'bgr24'
    }
    'tiff' { 
        $encParams = @('-c:v', 'tiff', '-compression_algo', '1')
        $pixFmt = 'rgb24'
    }
    'tif' { 
        $encParams = @('-c:v', 'tiff', '-compression_algo', '1')
        $pixFmt = 'rgb24'
    }
    default {
        Write-Warning "不支持的扩展名 '$ext'，将使用 WebP 编码"
        $ext = 'webp'
        $encParams = @('-c:v', 'libwebp', '-q:v', '80')
        $pixFmt = 'yuva420p'
    }
}

# 如果需要，添加像素格式参数
if ($pixFmt -ne '') {
    $encParams = @('-pix_fmt', $pixFmt) + $encParams
}

$videoExtensions = @('*.mp4', '*.mkv', '*.avi', '*.mov', '*.webm', '*.m4v')
$videos = Get-ChildItem -Recurse -Include $videoExtensions -File
$total = $videos.Count
$current = 0

foreach ($video in $videos) {
    $current++
    $videoName = $video.Name
    $videoDir  = $video.DirectoryName
    $thumbDir  = Join-Path $videoDir $ThumbFolderName
    
    # 计算文件名的 SHA-256
    $hashInput = [System.Text.Encoding]::UTF8.GetBytes($videoName)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($hashInput)
    $hash = -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
    
    $thumbPath = Join-Path $thumbDir "$hash.$ext"
    
    if (-not (Test-Path $thumbPath)) {
        Write-Host "[$current/$total] 生成: $($video.FullName) -> $ext"
        if (-not (Test-Path $thumbDir)) {
            New-Item -ItemType Directory -Path $thumbDir -Force | Out-Null
        }
        # 提取第一帧，使用 image2 模式确保单张图片输出，并更新已存在文件
        & $FFmpegPath -loglevel warning -i $video.FullName -vf "select=eq(n\,0)" -vframes 1 -f image2 -update 1 $encParams "$thumbPath" -y
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "失败: $($video.FullName)"
        }
    } else {
        Write-Host "[$current/$total] 跳过: $($video.FullName) (缩略图已存在)"
    }
}

Write-Host "完成！共处理 $total 个视频"