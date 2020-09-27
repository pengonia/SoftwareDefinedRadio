#requires -version 2
<#
.SYNOPSIS
    This module contains functions useful for software-define radio scripts.

.DESCRIPTION
    These functions won't work standalone. Import this module from a PowerShell
    script.

.NOTES
  Version:        1.0
  Author:         John Mayson, KC4VJO, <john@mayson.us>
  Creation Date:  2020-09-26
  Purpose/Change: Initial script development
#>

#
# This function kills off all possibly open windows to release the SDR device.
#

Function Stop-DSDPlus {
	Start-Process "taskkill" -ArgumentList "/F","/IM","CMD.exe"
	Start-Process "taskkill" -ArgumentList "/F","/IM","DSDPlus.exe"
	Start-Process "taskkill" -ArgumentList "/F","/IM","FMP24.exe"
	Start-Process "taskkill" -ArgumentList "/F","/IM","nrsc5.exe"
}


#
# This function requires the installation of DUMP1090 ADS-B and Virtual Radar software.
# http://planeplotter.pbworks.com/w/page/79995023/Dump1090 
# http://www.virtualradarserver.co.uk/
#
# It will start the application, and open the default web browser.
#

Function Start-VirtualRadar {
    Start-Process "R:\Tools\dump1090\dump1090.exe" -ArgumentList "--interactive","--net","--net-ro-size 500","--net-ro-rate 5","--net-buffer 5","--net-beast","--mlat"
    Start-Process "C:\Program Files\VirtualRadar\VirtualRadar.exe"
    Start "http://127.0.0.1/VirtualRadar"
}


#
# This function requires the nrsc5.exe program. It can be difficult to find, so I offer
# it here https://kc4vjo.org/_media/sdr/nrsc5.zip
# 
# This allows tuning local HD FM stations. The frequency and digital number are required.
#
# Examples:
#     Start-HDR -Frequency 90.5 -Channel 1
#     Start-HDR -Frequency 103.5 -Channel 0
# 

Function Start-HDR {
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true)][string]$Frequency,
		[Parameter(Mandatory=$true)][string]$Channel
	)

    Start-Process "R:\Tools\nrsc5\nrsc5.exe" -ArgumentList "${Frequency}e6","$Channel"
}


#
# The next two functions do not work. Hopefully they will in my next release.
#

# Function Start-Cvlc {
# 	[cmdletbinding()]
# 	param (
# 		[Parameter(Mandatory=$false)][string]$Rate = "200k"
# 	)
# 
# 	$command = "C:\Program Files\VideoLAN\VLC\vlc.exe"
# 	$params = @(
# 		'--demux=rawaud'
# 		'--rawaud-channels=1'
# 		'--rawaud-samplerate=${Rate}'
# 		'--rawaud-fourcc=s16l'
# 		'-'
# 	)
# 	& "$command" #  @params
# }


# Function Start-RtlFm {
# 	[cmdletbinding()]
# 	param (
# 		[Parameter(Mandatory=$true)][string]$Frequency,
# 		[Parameter(Mandatory=$false)][string]$Mode = "nbfm",
# 		[Parameter(Mandatory=$false)][string]$Squelch = "0",
# 		[Parameter(Mandatory=$false)][string]$Gain = "49.6",
# 		[Parameter(Mandatory=$false)][string]$Rate = "200k"
# 	)
# 
# 	$command = 'R:\Tools\nrsc5\rtl_fm.exe'
# 	$params = @(
# 		'-M'
# 		'${Mode}'
# 		'-l${Squelch}'
# 		'-A std'
# 		'-p0'
# 		'-s${Rate}'
# 		'-r${Rate}'
# 		'-g${Gain}'
# 		'-f${Frequency}'
# 		'-'
# 	)
# 
# 	& $command @params
# }


#
# This functional is scan conventional frequencies passed to the function
#
# Examples:
#     Start-ConventionalScanner -Entries "162.4,162.425,162.45,162.475,162.5"
#

Function Start-ConventionalScanning {
	[cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Entries,
        [string]$Latitude = "30.3911378",
        [string]$Longitude = "-97.6630562"
        )

    Set-Location "R:\Tools\DSDPlus"

# Add latitude & longitude to FMP24.cfg file
    $BaseConfig = Get-Content -Path "R:\Tools\DSDPlus\base.cfg"
    Set-Content -Path "R:\Tools\DSDPlus\FMP24.cfg" -Value $BaseConfig -Force
    Add-Content -Path "R:\Tools\DSDPlus\FMP24.cfg" -Value "$Latitude $Longitude"

# Add control and alternate channels to FMP24.ScanList file
    Set-Content -Path "R:\Tools\DSDPlus\FMP24.ScanList" -Value $Entries.Replace(",","`n") -Force
    Start-Process "R:\Tools\DSDPlus\FMP24.exe" -ArgumentList "-_3","-s1","-i1","-o20001","-P0.0","5","-b12.5"
    Start-Process "R:\Tools\DSDPlus\DSDPlus.exe" -ArgumentList "-_11","-i20001","-m1"
}


#
# The function will start tracking any system compatible with DSDPlus Fast Lane and the
# software is required. https://www.dsdplus.com/dsdplus-fast-lane-program/
#
# Right now the function only handles P25 and DMR.
#
# Examples:
#    Start-Trunking -Protocol "P25" -Primary "857.0625" -Alternate "858.0625"
#    Start-Trunking -Protocol "DMR" -Primary "770.6625" -Alternate "771.8625"
#

Function Start-Trunking {
	[cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Primary,
        [string]$Alternate,
        [Parameter(Mandatory=$true)][string]$Protocol,
        [string]$Latitude = "30.3911378",
        [string]$Longitude = "-97.6630562"
    )

    Set-Location "R:\Tools\DSDPlus"

# Add latitude & longitude to FMP24.cfg file
    $BaseConfig = Get-Content -Path "R:\Tools\DSDPlus\base.cfg"
    Set-Content -Path "R:\Tools\DSDPlus\FMP24.cfg" -Value $BaseConfig -Force
    Add-Content -Path "R:\Tools\DSDPlus\FMP24.cfg" -Value "$Latitude $Longitude"

# Add control and alternate channels to FMP24.ScanList file
    Set-Content -Path "R:\Tools\DSDPlus\FMP24.ScanList" -Value $Primary -Force
    Add-Content -Path "R:\Tools\DSDPlus\FMP24.ScanList" -Value $Alternate.Replace(",","`n")

    If ($Protocol -Eq "P25") {
# Start P25 Trunking
      Start-Process "R:\Tools\DSDPlus\FMP24.exe" -ArgumentList "-_3","-rc","-i1","-o20001","-P0.0","-v0","-b12.5","-f${Primary}e6"
      Start-Process "R:\Tools\DSDPlus\DSDPlus.exe" -ArgumentList "-_11","-E","-i20001","-PBmp3","-r1","-T","-wch24","-wcl0,0"
   } ElseIf ($Protocol -Eq "DMR") {

# Start DMR trunking
        Start-Process "R:\Tools\DSDPlus\FMP24.exe" -ArgumentList "-_3","-i1","-o20001","-P0.0","-v5","-b12.5","-g49.6","-f${Primary}e6"
        Start-Process "R:\Tools\DSDPlus\DSDPlus.exe" -ArgumentList "-_11","-rv","-fr","-i20001","-PBmp3","-v0","-wch24","-wcl0,0"
  } Else {
        Write-Output "Invalid protocol specified"
  }
}


#
# I decided to combine trunking into a single function. I left this here for backward
# compatibility. I recommend you don't use it.
#

Function Start-P25Trunking {
	[cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Primary,
        [string]$Alternate,
        [string]$Latitude = "30.3911378",
        [string]$Longitude = "-97.6630562"
    )

    Start-Trunking -Protocol "P25" -Primary "${Primary}" -Alternate "${Alternate}" -Latitude "${Latitude}" -Longitude "${Longitude}"
}


#
# I decided to combine trunking into a single function. I left this here for backward
# compatibility. I recommend you don't use it.
#

Function Start-DMRTrunking {
	[cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Primary,
        [string]$Alternate,
        [string]$Latitude = "30.3911378",
        [string]$Longitude = "-97.6630562"
    )

    Start-Trunking -Protocol "DMR" -Primary "${Primary}" -Alternate "${Alternate}" -Latitude "${Latitude}" -Longitude "${Longitude}"
}


Function New-DesktopShortcut {
	[cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$ShortcutName,
        [Parameter(Mandatory=$true)][string]$IconLocation
    )

	$ShortcutLocation = "$env:USERPROFILE\OneDrive\Desktop\${ShortcutName}.lnk"
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
	$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $Shortcut.Arguments = "-noexit -ExecutionPolicy Bypass -WindowStyle Hidden -File `"${Path}`""
        $Shortcut.WorkingDirectory = "R:\Tools\DSDPlus"
        $Shortcut.IconLocation = $IconLocation
	$Shortcut.Save()
}


Function New-StartMenuShortcut {
	[cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$ShortcutName,
        [Parameter(Mandatory=$true)][string]$IconLocation
    )

	$ShortcutLocation = "$env:USERPROFILE\Start Menu\Programs\${ShortcutName}.lnk"
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
	$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $Shortcut.Arguments = "-noexit -ExecutionPolicy Bypass -WindowStyle Hidden -File `"${Path}`""
        $Shortcut.WorkingDirectory = "R:\Tools\DSDPlus"
        $Shortcut.IconLocation = $IconLocation
	$Shortcut.Save()
}
