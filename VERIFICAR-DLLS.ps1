$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Game = Join-Path $Root 'Game'
$local = @('D3DImm.dll','DDraw.dll','Glide.dll','Glide2x.dll','Glide3x.dll','TarzanImagem.dll','winmm.dll')
Write-Host '=== TARZAN v1.5.1 - VERIFICACAO DE DLLs ===' -ForegroundColor Cyan
foreach($n in $local){
  $p=Join-Path $Game $n
  if(Test-Path $p){ Write-Host ('OK   local: '+$n) -ForegroundColor Green }
  else { Write-Host ('FALTA local: '+$n) -ForegroundColor Red }
}
$sys32 = Join-Path $env:WINDIR 'System32'
$wow64 = Join-Path $env:WINDIR 'SysWOW64'
foreach($n in @('dinput.dll','dinput8.dll','winmm.dll')){
  $paths=@(Join-Path $wow64 $n, Join-Path $sys32 $n)
  $found=$paths | Where-Object { Test-Path $_ } | Select-Object -First 1
  if($found){ Write-Host ('OK   Windows: '+$n+' -> '+$found) -ForegroundColor Green }
  else { Write-Host ('FALTA Windows: '+$n) -ForegroundColor Yellow }
}
Write-Host ''
Write-Host 'Observacao: dinput.dll/dinput8.dll sao componentes do Windows/DirectX; nao eram arquivos locais das builds portateis anteriores.' -ForegroundColor Gray
