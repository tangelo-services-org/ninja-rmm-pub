Function LogWrite
{
    # Expects $env:NINJA_LOG_FILE to be set to a file
    Param (
        [string]$logstring, 
        [boolean]$writehost = $false
    )

    if ($env:NINJA_LOG_FILE)
    {
        $logfile = $env:NINJA_LOG_FILE
    }
    else
    {
        $logfile = 'C:\ProgramData\NinjaRMMAgent\tglo_ninja_log.txt'
    }

    if (-not (Test-Path $logfile))
    {
        New-Item $logfile
    }

    if ($writehost)
    {
        Write-Host $logstring
    }
    Add-Content $Logfile -Value "[$($(Get-Date).ToString('yyyyMMddHHmm'))]: $logstring"
}