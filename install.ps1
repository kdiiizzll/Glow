# Matrix Screensaver installer (Windows 10/11, PowerShell 5+). Run from the folder that contains these files:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
# Installs to %USERPROFILE%\Matrix and starts the server + agent at login.
param([switch]$NoServer)
$ErrorActionPreference='Continue'
$src=Split-Path -Parent $MyInvocation.MyCommand.Path
$dir="$env:USERPROFILE\Matrix"; New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item "$src\index.html" "$dir\saver.html" -Force
foreach($f in 'server.ps1','panel.html','agent.ps1','peers.txt'){ if(Test-Path "$src\$f"){ Copy-Item "$src\$f" "$dir\$f" -Force } }
# stop any previous copy
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | ?{ $_.CommandLine -match 'Matrix\\(agent|server)\.ps1' } | %{ Stop-Process -Id $_.ProcessId -Force -EA SilentlyContinue }
$startup=[Environment]::GetFolderPath('Startup')
function Vbs($name,$ps){ $v="$startup\$name.vbs"; Set-Content $v ('CreateObject("WScript.Shell").Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""' + $ps + '""", 0, False'); Start-Process wscript.exe "`"$v`"" }
if(-not $NoServer){
 # one-time admin step: let the server listen on port 8765 and allow it through the firewall (private networks only)
 $cmd="netsh http add urlacl url=http://+:8765/ user=$env:USERDOMAIN\$env:USERNAME; netsh advfirewall firewall delete rule name=MatrixScreensaver; netsh advfirewall firewall add rule name=MatrixScreensaver dir=in action=allow protocol=TCP localport=8765 profile=private"
 Start-Process powershell -ArgumentList "-NoProfile -Command $cmd" -Verb RunAs -Wait
 Vbs 'MatrixServer' "$dir\server.ps1"; Start-Sleep 3
}
Vbs 'MatrixAgent' "$dir\agent.ps1"
$ws=New-Object -ComObject WScript.Shell; $l=$ws.CreateShortcut("$([Environment]::GetFolderPath('Desktop'))\Matrix Control.url")
$l.TargetPath='http://localhost:8765/'; $l.Save()
"Installed to $dir. Open http://localhost:8765/ (or the 'Matrix Control' desktop shortcut) to turn it on."
