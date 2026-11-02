$ErrorActionPreference='Continue'
$dir=Split-Path -Parent $MyInvocation.MyCommand.Path
$modes=@('matrix','starfield','fireworks','lava','paris'); $state=@{on=$false;mode='matrix'}
# optional: list the other PCs' IP addresses (one per line) in peers.txt next to this script
$peers=@(); if(Test-Path "$dir\peers.txt"){ $peers=@(Get-Content "$dir\peers.txt" | %{ $_.Trim() } | ?{ $_ -and -not $_.StartsWith('#') }) }
foreach($p in $peers){ try{ $s=Invoke-RestMethod "http://$($p):8765/state" -TimeoutSec 1; if($s.mode){ $state.on=[bool]$s.on; $state.mode=$s.mode; break } }catch{} }
$l=New-Object System.Net.HttpListener; $l.Prefixes.Add('http://+:8765/'); $l.Start()
while($l.IsListening){
 try{
  $ctx=$l.GetContext(); $req=$ctx.Request; $res=$ctx.Response; $p=$req.Url.AbsolutePath.ToLower()
  $res.Headers.Add('Access-Control-Allow-Origin','*'); $res.Headers.Add('Access-Control-Allow-Private-Network','true'); $res.Headers.Add('Cache-Control','no-store')
  $type='application/json'; $body=$null
  switch($p){
   '/set'   { $q=$req.QueryString; if($q['on']){ $state.on=($q['on'] -eq '1') }; if($q['mode'] -and ($modes -contains $q['mode'])){ $state.mode=$q['mode'] } }
   '/saver' { $type='text/html; charset=utf-8'; $body=[IO.File]::ReadAllBytes("$dir\saver.html") }
   '/peers' { $body=[Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -Compress -InputObject @($peers))) }
   '/'      { $type='text/html; charset=utf-8'; $body=[IO.File]::ReadAllBytes("$dir\panel.html") }
  }
  if(-not $body){ $body=[Text.Encoding]::UTF8.GetBytes((@{on=$state.on;mode=$state.mode}|ConvertTo-Json -Compress)) }
  $res.ContentType=$type; $res.ContentLength64=$body.Length; $res.OutputStream.Write($body,0,$body.Length); $res.Close()
 }catch{ Start-Sleep -Milliseconds 200 }
}
