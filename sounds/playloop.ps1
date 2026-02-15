# ---------------- CONFIG ----------------
$audioPath1 = "C:\sounds\essential.mp3"
$audioPath2 = "C:\sounds\loud-ahh-chicken-on-tree.mp3"

$base = "https://troll-lab-default-rtdb.asia-southeast1.firebasedatabase.app/soundSystem"
# ----------------------------------------

$trigger1Url = "$base/trigger.json"
$trigger2Url = "$base/trigger2.json"

$statusUrl   = "$base/pcStatus.json"
$nameUrl     = "$base/PCname.json"

$sound1Url   = "$base/soundLoaded.json"
$sound2Url   = "$base/soundLoaded2.json"
$lastSeenUrl = "$base/lastSeen.json"

$pcName = $env:COMPUTERNAME

Add-Type -AssemblyName presentationCore

# ---- volume helper ----
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Volume {
  [DllImport("user32.dll")]
  public static extern void keybd_event(byte vk, byte scan, int flags, int extra);
}
"@

function Set-MaxVolume {
    for ($i=0; $i -lt 50; $i++) {
        [Volume]::keybd_event(0xAF,0,0,0)
        Start-Sleep -Milliseconds 15
    }
}

# ---- players ----
$player1 = New-Object System.Windows.Media.MediaPlayer
$player2 = New-Object System.Windows.Media.MediaPlayer

if (Test-Path $audioPath1) { $player1.Open([Uri]$audioPath1) }
if (Test-Path $audioPath2) { $player2.Open([Uri]$audioPath2) }

Start-Sleep -Milliseconds 500

# ---- initial status ----
Invoke-RestMethod $statusUrl -Method Put -ContentType "application/json" `
    -Body '"online"' | Out-Null

Invoke-RestMethod $nameUrl -Method Put -ContentType "application/json" `
    -Body ('"' + $pcName + '"') | Out-Null

# ---------------- LOOP (1 second) ----------------
while ($true) {

    try {
        $now = Get-Date

        # heartbeat
        Invoke-RestMethod $lastSeenUrl -Method Put -ContentType "application/json" `
            -Body ('"' + $now.ToString("s") + '"') | Out-Null

        # online flag
        Invoke-RestMethod $statusUrl -Method Put -ContentType "application/json" `
            -Body '"online"' | Out-Null

        # desktop name refresh
        Invoke-RestMethod $nameUrl -Method Put -ContentType "application/json" `
            -Body ('"' + $pcName + '"') | Out-Null

        # ---- sound file checks ----
        $exists1 = Test-Path $audioPath1
        $exists2 = Test-Path $audioPath2

        Invoke-RestMethod $sound1Url -Method Put -ContentType "application/json" `
            -Body ($(if($exists1){"true"}else{"false"})) | Out-Null

        Invoke-RestMethod $sound2Url -Method Put -ContentType "application/json" `
            -Body ($(if($exists2){"true"}else{"false"})) | Out-Null

        # ---- trigger 1 ----
        $t1 = Invoke-RestMethod $trigger1Url -TimeoutSec 2
        if ($t1 -eq $true -and $exists1) {
            Set-MaxVolume
            $player1.Position = [TimeSpan]::Zero
            $player1.Play()

            Invoke-RestMethod $trigger1Url -Method Put -ContentType "application/json" `
                -Body "false" | Out-Null
        }

        # ---- trigger 2 ----
        $t2 = Invoke-RestMethod $trigger2Url -TimeoutSec 2
        if ($t2 -eq $true -and $exists2) {
            Set-MaxVolume
            $player2.Position = [TimeSpan]::Zero
            $player2.Play()

            Invoke-RestMethod $trigger2Url -Method Put -ContentType "application/json" `
                -Body "false" | Out-Null
        }

    }
    catch {
        # ignore transient network errors
    }

    Start-Sleep -Seconds 1
}
