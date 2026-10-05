# Tarzan PC Modernizado - Configurador Grafico v1.5.1
# Nao altera tarzan.fsd nem saves. Faz backup antes de mudar configuracoes.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Game = Join-Path $Root 'Game'
$Conf = Join-Path $Game 'dgVoodoo.conf'
$ProfileDir = Join-Path $Root 'GraphicsProfiles'
$Cfg = Join-Path $Game 'tarzan.cfg'
$BackupDir = Join-Path $Root 'Backups-Graficos'
if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }

function Set-IniValue([string]$Path,[string]$Section,[string]$Key,[string]$Value) {
    $lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $Path)
    $sec = -1
    for($i=0;$i -lt $lines.Count;$i++) {
        if($lines[$i] -match ('^\s*\['+[regex]::Escape($Section)+'\]\s*$')) { $sec=$i; break }
    }
    if($sec -lt 0) {
        $lines.Add('')
        $lines.Add('['+$Section+']')
        $lines.Add($Key+' = '+$Value)
    } else {
        $end=$lines.Count
        for($i=$sec+1;$i -lt $lines.Count;$i++) { if($lines[$i] -match '^\s*\[.+\]\s*$') { $end=$i; break } }
        $found=$false
        for($i=$sec+1;$i -lt $end;$i++) {
            if($lines[$i] -match ('^\s*'+[regex]::Escape($Key)+'\s*=')) {
                $lines[$i]=$Key+' = '+$Value; $found=$true; break
            }
        }
        if(!$found) { $lines.Insert($end,$Key+' = '+$Value) }
    }
    [System.IO.File]::WriteAllLines($Path,$lines,[System.Text.Encoding]::ASCII)
}

function Get-IniValue([string]$Path,[string]$Section,[string]$Key,[string]$Default='') {
    if(!(Test-Path $Path)){ return $Default }
    $inSection=$false
    foreach($line in Get-Content -LiteralPath $Path) {
        if($line -match '^\s*\[(.+)\]\s*$') { $inSection=($matches[1] -ieq $Section); continue }
        if($inSection -and $line -match ('^\s*'+[regex]::Escape($Key)+'\s*=\s*(.*)$')) { return $matches[1].Trim() }
    }
    return $Default
}

function Make-Backup {
    $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
    if(Test-Path $Conf){ Copy-Item $Conf (Join-Path $BackupDir ('dgVoodoo-'+$stamp+'.conf')) -Force }
    if(Test-Path $Cfg){ Copy-Item $Cfg (Join-Path $BackupDir ('tarzan-'+$stamp+'.cfg')) -Force }
}

$form = New-Object System.Windows.Forms.Form
$form.Text='Tarzan PC Modernizado - Graficos v1.5.1'
$form.Size=New-Object System.Drawing.Size(620,590)
$form.StartPosition='CenterScreen'
$form.FormBorderStyle='FixedDialog'
$form.MaximizeBox=$false
$form.BackColor=[System.Drawing.Color]::FromArgb(28,31,36)
$form.ForeColor=[System.Drawing.Color]::White
$form.Font=New-Object System.Drawing.Font('Segoe UI',10)

$title=New-Object System.Windows.Forms.Label
$title.Text='TARZAN - GRAFICOS MODERNOS'
$title.Font=New-Object System.Drawing.Font('Segoe UI Semibold',16)
$title.Location=New-Object System.Drawing.Point(24,18)
$title.Size=New-Object System.Drawing.Size(560,34)
$form.Controls.Add($title)

$note=New-Object System.Windows.Forms.Label
$note.Text='Base estavel: nao altera texturas/FSD nem saves. Opcoes gravadas no dgVoodoo.'
$note.Location=New-Object System.Drawing.Point(26,55)
$note.Size=New-Object System.Drawing.Size(555,38)
$note.ForeColor=[System.Drawing.Color]::LightGray
$form.Controls.Add($note)

function Add-Label($text,$x,$y){
 $l=New-Object System.Windows.Forms.Label; $l.Text=$text; $l.Location=New-Object System.Drawing.Point($x,$y); $l.Size=New-Object System.Drawing.Size(210,24); $form.Controls.Add($l); return $l
}
function Add-Combo($items,$x,$y,$w=275){
 $c=New-Object System.Windows.Forms.ComboBox; $c.DropDownStyle='DropDownList'; $c.Location=New-Object System.Drawing.Point($x,$y); $c.Size=New-Object System.Drawing.Size($w,28); [void]$c.Items.AddRange([object[]]$items); $c.SelectedIndex=0; $form.Controls.Add($c); return $c
}

Add-Label 'Renderizador' 28 105 | Out-Null
$renderer=Add-Combo @('Glide (mais compativel)','Direct3D (filtros avancados)') 270 101
Add-Label 'Resolucao' 28 145 | Out-Null
$res=Add-Combo @('Original do jogo','1280x720 (720p)','1920x1080 (1080p)','2560x1440 (1440p)','3840x2160 (4K)','Resolucao do monitor') 270 141
Add-Label 'Modo de tela' 28 185 | Out-Null
$screen=Add-Combo @('Janela','Borderless','Fullscreen exclusivo') 270 181
Add-Label 'Anti-aliasing' 28 225 | Out-Null
$aa=Add-Combo @('Off','MSAA 2x','MSAA 4x','MSAA 8x') 270 221
Add-Label 'Filtragem 3D' 28 265 | Out-Null
$filter=Add-Combo @('Bilinear','Trilinear','Anisotropico 4x','Anisotropico 8x','Anisotropico 16x') 270 261
Add-Label 'V-Sync' 28 305 | Out-Null
$vsync=Add-Combo @('On','Off') 270 301
Add-Label 'Sharpening / nitidez de upscale' 28 345 | Out-Null
$sharp=Add-Combo @('Off (Bicubic)','Baixo (Lanczos-2)','Medio (Lanczos-3)') 270 341

$fx=New-Object System.Windows.Forms.Label
$fx.Text='FXAA: reservado para modulo de pos-processamento; nao e simulado com MSAA.'
$fx.Location=New-Object System.Drawing.Point(28,386)
$fx.Size=New-Object System.Drawing.Size(550,38)
$fx.ForeColor=[System.Drawing.Color]::Khaki
$form.Controls.Add($fx)

$status=New-Object System.Windows.Forms.Label
$status.Location=New-Object System.Drawing.Point(28,430)
$status.Size=New-Object System.Drawing.Size(550,42)
$status.ForeColor=[System.Drawing.Color]::LightGreen
$form.Controls.Add($status)

# Load current values where possible
$curRes=Get-IniValue $Conf 'DirectX' 'Resolution' 'unforced'
switch($curRes){
 '1280x720' {$res.SelectedIndex=1}; '1920x1080' {$res.SelectedIndex=2}; '2560x1440' {$res.SelectedIndex=3}; '3840x2160' {$res.SelectedIndex=4}; 'desktop' {$res.SelectedIndex=5}; default {$res.SelectedIndex=0}
}
$curAA=Get-IniValue $Conf 'DirectX' 'Antialiasing' 'off'
switch($curAA){'2x'{$aa.SelectedIndex=1};'4x'{$aa.SelectedIndex=2};'8x'{$aa.SelectedIndex=3};default{$aa.SelectedIndex=0}}
$curF=Get-IniValue $Conf 'DirectX' 'Filtering' 'bilinear'
switch($curF){'trilinear'{$filter.SelectedIndex=1};'4'{$filter.SelectedIndex=2};'8'{$filter.SelectedIndex=3};'16'{$filter.SelectedIndex=4};default{$filter.SelectedIndex=0}}
$curV=Get-IniValue $Conf 'DirectX' 'ForceVerticalSync' 'true'; if($curV -ieq 'false'){$vsync.SelectedIndex=1}
$curR=Get-IniValue $Conf 'GeneralExt' 'Resampling' 'bicubic'; switch($curR){'lanczos-2'{$sharp.SelectedIndex=1};'lanczos2'{$sharp.SelectedIndex=1};'lanczos-3'{$sharp.SelectedIndex=2};'lanczos3'{$sharp.SelectedIndex=2};default{$sharp.SelectedIndex=0}}
$curFS=Get-IniValue $Conf 'General' 'FullScreenMode' 'true'; $curWA=Get-IniValue $Conf 'GeneralExt' 'WindowedAttributes' ''
if($curFS -ieq 'true'){$screen.SelectedIndex=2}elseif($curWA -match 'borderless'){$screen.SelectedIndex=1}else{$screen.SelectedIndex=0}

$save=New-Object System.Windows.Forms.Button
$save.Text='Salvar configuracoes'
$save.Location=New-Object System.Drawing.Point(28,492)
$save.Size=New-Object System.Drawing.Size(190,38)
$form.Controls.Add($save)
$play=New-Object System.Windows.Forms.Button
$play.Text='Salvar e iniciar Tarzan'
$play.Location=New-Object System.Drawing.Point(228,492)
$play.Size=New-Object System.Drawing.Size(190,38)
$form.Controls.Add($play)
$close=New-Object System.Windows.Forms.Button
$close.Text='Fechar'
$close.Location=New-Object System.Drawing.Point(428,492)
$close.Size=New-Object System.Drawing.Size(150,38)
$form.Controls.Add($close)

function Apply-Settings {
    if(!(Test-Path $Conf)){ [System.Windows.Forms.MessageBox]::Show('Game\\dgVoodoo.conf nao encontrado.','Tarzan'); return $false }
    Make-Backup
    $r=@('unforced','1280x720','1920x1080','2560x1440','3840x2160','desktop')[$res.SelectedIndex]
    $a=@('off','2x','4x','8x')[$aa.SelectedIndex]
    $f=@('bilinear','trilinear','4','8','16')[$filter.SelectedIndex]
    $v=if($vsync.SelectedIndex -eq 0){'true'}else{'false'}
    $rs=@('bicubic','lanczos-2','lanczos-3')[$sharp.SelectedIndex]

    # Advanced filtering is a Direct3D feature in dgVoodoo. Auto-select D3D if requested.
    if($filter.SelectedIndex -gt 0){ $renderer.SelectedIndex=1 }
    if($renderer.SelectedIndex -eq 1){
        $src=Join-Path $ProfileDir 'tarzan-direct3d.cfg'
        if(Test-Path $src){ Copy-Item $src $Cfg -Force }
    } else {
        $src=Join-Path $ProfileDir 'tarzan-glide.cfg'
        if(Test-Path $src){ Copy-Item $src $Cfg -Force }
    }

    Set-IniValue $Conf 'Glide' 'Resolution' $r
    Set-IniValue $Conf 'DirectX' 'Resolution' $r
    Set-IniValue $Conf 'Glide' 'Antialiasing' $a
    Set-IniValue $Conf 'DirectX' 'Antialiasing' $a
    Set-IniValue $Conf 'Glide' 'ForceVerticalSync' $v
    Set-IniValue $Conf 'DirectX' 'ForceVerticalSync' $v
    Set-IniValue $Conf 'DirectX' 'Filtering' $f
    Set-IniValue $Conf 'DirectX' 'Mipmapping' 'appdriven'
    Set-IniValue $Conf 'Glide' 'TMUFiltering' 'bilinear'
    Set-IniValue $Conf 'GeneralExt' 'Resampling' $rs
    Set-IniValue $Conf 'DirectXExt' 'ExtraEnumeratedResolutions' '1280x720, 1920x1080, 2560x1440, 3840x2160'

    switch($screen.SelectedIndex){
      0 { Set-IniValue $Conf 'General' 'FullScreenMode' 'false'; Set-IniValue $Conf 'GeneralExt' 'WindowedAttributes' ''; Set-IniValue $Conf 'GeneralExt' 'FullscreenAttributes' '' }
      1 { Set-IniValue $Conf 'General' 'FullScreenMode' 'false'; Set-IniValue $Conf 'GeneralExt' 'WindowedAttributes' 'borderless, fullscreensize'; Set-IniValue $Conf 'GeneralExt' 'FullscreenAttributes' '' }
      2 { Set-IniValue $Conf 'General' 'FullScreenMode' 'true'; Set-IniValue $Conf 'GeneralExt' 'WindowedAttributes' ''; Set-IniValue $Conf 'GeneralExt' 'FullscreenAttributes' '' }
    }
    Set-IniValue $Conf 'General' 'KeepWindowAspectRatio' 'true'
    Set-IniValue $Conf 'General' 'ScalingMode' 'stretched_ar'
    $status.Text='Salvo. Backup criado em Backups-Graficos.'
    return $true
}

$save.Add_Click({ [void](Apply-Settings) })
$play.Add_Click({ if(Apply-Settings){ $exe=Join-Path $Root 'Tarzan-Moderno.exe'; if(Test-Path $exe){ Start-Process -FilePath $exe -WorkingDirectory $Root } else { [System.Windows.Forms.MessageBox]::Show('Tarzan-Moderno.exe nao encontrado.','Tarzan') } } })
$close.Add_Click({ $form.Close() })
[void]$form.ShowDialog()
