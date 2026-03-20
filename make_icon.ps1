Add-Type -AssemblyName System.Drawing

$size = 1024
$cx = [float]($size / 2)
$cy = [float]($size / 2) + 60
$s = [float]($size) / 400.0

function Draw-Paw {
    param($g, $white)
    # Ana avuc ici
    $g.FillEllipse($white, $cx - 85*$s, $cy - 70*$s, 170*$s, 140*$s)
    # 4 parmak
    $g.FillEllipse($white, $cx - 75*$s - 28*$s, $cy - 90*$s - 33*$s, 56*$s, 66*$s)
    $g.FillEllipse($white, $cx - 25*$s - 28*$s, $cy - 115*$s - 33*$s, 56*$s, 66*$s)
    $g.FillEllipse($white, $cx + 25*$s - 28*$s, $cy - 115*$s - 33*$s, 56*$s, 66*$s)
    $g.FillEllipse($white, $cx + 75*$s - 28*$s, $cy - 90*$s - 33*$s, 56*$s, 66*$s)
}

# Ana ikon (mor arka plan)
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(108, 99, 255))
Draw-Paw $g ([System.Drawing.Brushes]::White)
$g.Dispose()
$bmp.Save("$PSScriptRoot\evcilhayvan_mobil2\assets\icon\app_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# Foreground ikon (seffaf arka plan)
$bmp2 = New-Object System.Drawing.Bitmap($size, $size)
$g2 = [System.Drawing.Graphics]::FromImage($bmp2)
$g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g2.Clear([System.Drawing.Color]::Transparent)
Draw-Paw $g2 ([System.Drawing.Brushes]::White)
$g2.Dispose()
$bmp2.Save("$PSScriptRoot\evcilhayvan_mobil2\assets\icon\app_icon_fg.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp2.Dispose()

Write-Host "Icons created OK"
