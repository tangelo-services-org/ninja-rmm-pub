function UninstallProgram
{
    param(
        [Parameter(Mandatory = $true)][string]$softwareName,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$softwareVersion
    )
    if ((CheckInstalled -softwareName $softwareName -softwareversion $softwareVersion) -ne 0)
    {
        # Software is not installed
        # Installer commands here
        Write-Host "Tried to uninstall $softwareName $softwareVersion but it is not installed"
        return 1
    }
    else
    {
        Write-Host 'Proceeding with uninstall...'
    }

    # Registry path where uninstall information is stored
    $uninstallKeyPaths = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
    $uninstallKeys = @()

    # Get all subkeys in the uninstall registry path
    foreach ($uninstallKeyPath in $uninstallKeyPaths)
    {
        $uninstallKeyPathKeys = Get-ChildItem -Path $uninstallKeyPath
        $uninstallKeys = $uninstallKeys + $uninstallKeyPathKeys
    }
    

    # Iterate through each subkey to find the program
    foreach ($key in $uninstallKeys)
    {
        $program = Get-ItemProperty -Path $key.PSPath
        # Write-Host "$($program.DisplayName) $($program.DisplayVersion)"
        if ($program.DisplayName -eq $softwareName -and $program.DisplayVersion -eq $softwareVersion)
        {
            $uninstallString = $program.UninstallString
            if ($uninstallString)
            {
                $parts = $uninstallString -split '\.exe', 2
                $exe = $parts[0].Trim('"') + '.exe'
                $arguments = $parts[1].Trim('"')
                 

                # Check if the uninstall command contains "/s" for silent uninstall
                if ($arguments -like '*/s' -or $arguments -like '*/S')
                {
                    # If it's already silent, execute it
                    # Write-Host "Uninstalling... $uninstallString"
                    # Invoke-Expression $uninstallString
                    
                }
                else
                {
                    # If not silent, add the "/s" and execute
                    $arguments = $arguments + ' /S'
                    # '--mode unattended'
                    # Write-Host "Uninstalling... $silentUninstallString"
                    # Invoke-Expression $silentUninstallString
                }
                Write-Host "exe $exe"
                Write-Host "args $arguments"
                $process = Start-Process "$exe" -ArgumentList $arguments -PassThru -Wait
                Write-Host $process
                break
            }
        }
    }

    # If the program is not found
    if (!$uninstallString)
    {
        Write-Host 'Program not found or uninstall information not available in the Registry.'
    }


}
