# Shortcut config
function CreateShortcut
{
    param (
        [Parameter(Mandatory = $true)][string]$shortcutPath,
        [Parameter(Mandatory = $true)][string]$targetPath,
        [string]$workingDir
    )

    if (-not $workingDir)
    {
        $workingDir = Split-Path $targetPath -Parent
    }

    LogWrite "Creating shortcut at $shortcutPath to $targetPath"
    New-Item -ItemType Directory -Path "$([System.IO.Path]::GetDirectoryName($shortcutPath))" -Force -ErrorAction SilentlyContinue

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetPath
    $shortcut.WorkingDirectory = $workingDir
    $shortcut.Save()
}
