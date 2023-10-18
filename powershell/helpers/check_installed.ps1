function CheckInstalled
{

    param(
        [Parameter(Mandatory = $true)][string]$softwareName,
        [Parameter(Mandatory = $true)][string]$softwareVersion
    )
    
    Write-Host "Checking if $softwareName $softwareVersion is installed..."
    foreach ($hive in @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' ))
    {
        $item = Get-ChildItem -LiteralPath $hive | Get-ItemProperty | Where-Object { $_.DisplayName -eq $softwareName -and $_.DisplayVersion -eq $softwareVersion }
        if ($item)
        {
            Write-Host "$softwareName $softwareVersion already installed, exiting..." 
            Return 0
        }
    }

    # Check if the software is installed, if it is - exit the script
    # $software = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name='$softwareName' AND Version='$softwareVersion'"
    # if ( $software )
    # {
    #     Write-Host "$softwareName $softwareVersion already installed, exiting..." 
    #     Return 0
    # }
}

