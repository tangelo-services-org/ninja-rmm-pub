function CheckInstalled
{

    param(
        [string]$softwareName,
        [string]$softwareVersion
    )
    
    Write-Host "Checking for $softwareName $softwareVersion..."
    foreach ($hive in @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' ))
    {
        $item = Get-ChildItem -LiteralPath $hive | Get-ItemProperty | Where-Object { $_.DisplayName -eq $softwareName -and $_.DisplayVersion -eq $softwareVersion }
        if ($item)
        {
            Write-Host "$softwareName $softwareVersion found, exiting..." 
            Return 0
        }
    }

    # Check if the software is installed, if it is - exit the script
    $software = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name='$softwareName' AND Version='$softwareVersion'"
    if ( $software )
    {
        Write-Host 
        Write-Host "$softwareName $softwareVersion found, exiting..." 
        Return 0
    }
}

