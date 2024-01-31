function UninstallProgram
{
    param(
        [Parameter(Mandatory = $true)][string]$softwareName,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$softwareVersion,
        [AllowEmptyString()][string]$uninstallArguments = '/S'
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

                if ($arguments)
                {
                    Write-Host "Using arguments found in registry: $exe $arguments"
                    $process = Start-Process "$exe" -ArgumentList $arguments -PassThru -Wait
                    Write-Host $process
                }
                else
                {
                    Write-Host "No arguments found in registry, using: $exe $uninstallArguments"
                    $process = Start-Process "$exe" -ArgumentList $uninstallArguments -PassThru -Wait
                }

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
