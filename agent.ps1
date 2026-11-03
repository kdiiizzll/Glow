$ErrorActionPreference='SilentlyContinue'
$dir=Split-Path -Parent $MyInvocation.MyCommand.Path
Add-Type -AssemblyName System.Windows.Forms
$edge=@("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe","$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")|?{Test-Path $_}|select -First 1
$bases=@('http://localhost:8765'); $base=$null
Add-Type @"
using System; using System.Runtime.InteropServices;
public class TB {
 [DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr p, IntPtr a, string c, string w);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
 [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr CreateCursor(IntPtr i, int x, int y, int w, int h, byte[] a, byte[] xo);
 [DllImport("user32.dll")] public static extern bool SetSystemCursor(IntPtr c, uint id);
 [DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);
 public static void Cursor(bool show){ if(show){ SystemParametersInfo(0x57,0,IntPtr.Zero,0); return; } uint[] ids={32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651}; foreach(uint id in ids){ byte[] a=new byte[128]; for(int k=0;k<128;k++)a[k]=0xFF; SetSystemCursor(CreateCursor(IntPtr.Zero,0,0,32,32,a,new byte[128]), id); } }
 public static void Bars(bool show){ foreach(string c in new string[]{"Shell_TrayWnd","Shell_SecondaryTrayWnd"}){ IntPtr h=IntPtr.Zero; while((h=FindWindowEx(IntPtr.Zero,h,c,null))!=IntPtr.Zero){ ShowWindow(h, show?5:0); } } }
}
"@
Add-Type @"
using System; using System.Collections.Generic; using System.Runtime.InteropServices;
public class BR {
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] public struct PM { public IntPtr h; [MarshalAs(UnmanagedType.ByValTStr,SizeConst=128)] public string d; }
 delegate bool MEP(IntPtr m, IntPtr dc, IntPtr r, IntPtr p);
 [DllImport("user32.dll")] static extern bool EnumDisplayMonitors(IntPtr dc, IntPtr c, MEP f, IntPtr p);
 [DllImport("dxva2.dll")] static extern bool GetNumberOfPhysicalMonitorsFromHMONITOR(IntPtr m, out uint n);
 [DllImport("dxva2.dll")] static extern bool GetPhysicalMonitorsFromHMONITOR(IntPtr m, uint n, [Out] PM[] a);
 [DllImport("dxva2.dll")] static extern bool GetMonitorBrightness(IntPtr h, out uint mn, out uint cur, out uint mx);
 [DllImport("dxva2.dll")] static extern bool SetMonitorBrightness(IntPtr h, uint v);
 [DllImport("dxva2.dll")] static extern bool DestroyPhysicalMonitors(uint n, PM[] a);
 static List<uint> saved=new List<uint>();
 static void Each(Action<IntPtr,int> a){ int i=0; EnumDisplayMonitors(IntPtr.Zero,IntPtr.Zero,(m,dc,r,p)=>{ uint n; if(GetNumberOfPhysicalMonitorsFromHMONITOR(m,out n)&&n>0){ PM[] arr=new PM[n]; if(GetPhysicalMonitorsFromHMONITOR(m,n,arr)){ foreach(PM pm in arr){ a(pm.h,i++); } DestroyPhysicalMonitors(n,arr);} } return true; },IntPtr.Zero); }
 public static void Max(){ saved.Clear(); Each((h,i)=>{ uint mn,cur,mx; if(GetMonitorBrightness(h,out mn,out cur,out mx)){ saved.Add(cur); SetMonitorBrightness(h,mx);} else saved.Add(uint.MaxValue); }); }
 public static void Restore(){ Each((h,i)=>{ if(i<saved.Count && saved[i]!=uint.MaxValue) SetMonitorBrightness(h,saved[i]); }); saved.Clear(); }
}
"@
$script:lap=$null
function BrightMax{ try{ [BR]::Max() }catch{}; try{ $w=Get-CimInstance -Namespace root/wmi WmiMonitorBrightness -EA Stop | select -First 1; if($w){ $script:lap=$w.CurrentBrightness; Get-CimInstance -Namespace root/wmi WmiMonitorBrightnessMethods | Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{Timeout=1;Brightness=[byte]100} | Out-Null } }catch{} }
function BrightRestore{ try{ [BR]::Restore() }catch{}; if($script:lap -ne $null){ try{ Get-CimInstance -Namespace root/wmi WmiMonitorBrightnessMethods | Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{Timeout=1;Brightness=[byte]$script:lap} | Out-Null }catch{}; $script:lap=$null } }
function Topmost{ Get-Process msedge | ?{ $_.MainWindowHandle -ne 0 } | %{ $c=(Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine; if($c -match '(Screensaver|Glow)\\profile(\d+)'){ $sc=[System.Windows.Forms.Screen]::AllScreens[[int]$matches[2]]; if($sc){ $b=$sc.Bounds; [TB]::SetWindowPos($_.MainWindowHandle,[IntPtr](-1),$b.X,$b.Y,$b.Width,$b.Height,0x40) | Out-Null; [TB]::SetForegroundWindow($_.MainWindowHandle) | Out-Null } } } }
[TB]::Bars($true); [TB]::Cursor($true)
function Running{ @(Get-CimInstance Win32_Process -Filter "Name='msedge.exe'"|?{$_.CommandLine -match '(Screensaver|Glow)\\profile'}) }
$script:up=$false; Running|%{ Stop-Process -Id $_.ProcessId -Force }
while($true){
 $s=$null
 foreach($b in (@($base)+$bases|?{$_}|select -Unique)){ try{ $s=Invoke-RestMethod "$b/state" -TimeoutSec 2; $base=$b; break }catch{} }
 if($s){
  if($s.on -and -not $script:up){ $script:up=$true
   (New-Object -ComObject Shell.Application).MinimizeAll(); Start-Sleep -Milliseconds 400
   $n=0; foreach($sc in [System.Windows.Forms.Screen]::AllScreens){ $b2=$sc.Bounds
    Start-Process $edge -ArgumentList @('--kiosk',"$base/saver",'--edge-kiosk-type=fullscreen','--no-first-run',"--window-position=$($b2.X),$($b2.Y)","--window-size=$($b2.Width),$($b2.Height)","--user-data-dir=`"$dir\profile$n`""); $n++ }
   Start-Sleep 3; [TB]::Bars($false); [TB]::Cursor($false); Topmost; Start-Sleep 1; Topmost; BrightMax
  } elseif(-not $s.on -and $script:up){ $script:up=$false; Running|%{ Stop-Process -Id $_.ProcessId -Force }; [TB]::Cursor($true); [TB]::Bars($true); BrightRestore; Start-Sleep -Milliseconds 300; (New-Object -ComObject Shell.Application).UndoMinimizeALL() }
 }
 Start-Sleep -Milliseconds 1000
}
