<# 
# SYNOPSIS
# gets ISO from Azure Files, mounts it and execute update
#
# DESCRIPTION
# Download ISO from Azure Files, mount it as data drive and execute setup to perform in-place upgrade
#
# NOTES
# Author      : Bojan Vrhovnik
# GitHub      : https://github.com/vrhovnik
# Version 2.0.0
# SHORT CHANGE DESCRIPTION: adding mounting options
#>
param(
    [Parameter(HelpMessage = "Provide the ISO location")]
    $FileShareLocation = "https://yourfileshare.file.core.windows.net",
    [Parameter(HelpMessage = "Provide the name of the ISO folder")]
    $IsoFolder = "iso",
    [Parameter(HelpMessage = "Provide the name of the ISO folder")]
    $IsoName = "ws2022.iso",
    [Parameter(HelpMessage = "Provide the username to mount")]
    $Username = "username",
    [Parameter(HelpMessage = "Provide the key to mount")]
    $Key = "yourkey"
)
Start-Transcript -Path "$HOME/Downloads/upgrade.log" -Force

Write-Output "Starting upgrade process..."
# check, if drives with filesystem have enough space
$commandInfo = Measure-Command {
    $drive = Get-PSDrive -PSProvider FileSystem C | Select-Object Free
    if (($drive.Free / 1GB) -lt 5)
    {
        $infoText = "You don't have enough space on C:\ drive for an upgrade - check settings"
        Write-Host $infoText
        Exit
    }
}
$executedInMs = $commandInfo.Milliseconds;
Write-Output "We checked drive C - there is enough space - command executed in $executedInMs ms"

# Save the password so the drive will persist on reboot
cmd.exe /C "cmdkey /add:`"$FileShareLocation`" /user:`"localhost\$Username`" /pass:`"$Key`""
# Mount the drive
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$FileShareLocation\$IsoFolder" -Persist
Set-Location "Z:"
Copy-Item $IsoName "$HOME\Downloads\$IsoName"
#if copying performance is an issue, you can use azcopy 
#https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10 
$imgDevice = Mount-DiskImage -ImagePath "$HOME\Downloads\$IsoName" -PassThru
Write-Information "Reading from $($imgDevice.DevicePath)\"

$mountedIso = Get-DiskImage -DevicePath $imgDevice.DevicePath | Get-Volume
Write-Information "Mounted ISO on $($mountedIso.DriveLetter):"
Set-Location "$($mountedIso.DriveLetter):"

$LocalPath = "$HOME\Downloads\"
Write-Information "Starting update process and savings logs to $LocalPath"
cmd.exe /C "setup /auto upgrade /quiet /compat scanonly /copylogs $LocalPath"

Stop-Transcript