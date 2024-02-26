function UninstallProgram
{
    param(
        [Parameter(Mandatory = $true)][string]$softwareName,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$softwareVersion,
        [AllowEmptyString()][string]$uninstallArguments
        # Note, if you specify $uninstallArguments, and there are also args found in the registry,
        # it will concat and use both.
        # Otherwise if you dont specify, and it cant find in registry, it will default to /S
        # If you do specify and it finds none in registry, it will use what you specified
    )
    if ((CheckInstalled -softwareName $softwareName -softwareversion $softwareVersion) -ne 0)
    {
        # Software is not installed
        # Installer commands here
        LogWrite "Tried to uninstall $softwareName $softwareVersion but it is not installed"
        return 1
    }
    else
    {
        LogWrite 'Proceeding with uninstall...'
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
        # LogWrite "$($program.DisplayName) $($program.DisplayVersion)"
        if ($program.DisplayName -eq $softwareName -and $program.DisplayVersion -eq $softwareVersion)
        {
            LogWrite $key
            if ($program.QuietUninstallString)
            {
                $uninstallString = $program.QuietUninstallString
            }
            else
            {
                $uninstallString = $program.UninstallString
            }
            
            if ($uninstallString)
            {
                # Handle msiexec strings a bit differently to normal .exe's
                if ($uninstallString -contains 'msiexec')
                {
                    $uninstallString.Replace('/I', '/x') # Sometimes they have the install flag specified instead of uninstall
                    if (-not ($uninstallString -contains '/qn')) # Sometimes they dont have the silent args specified
                    {
                        $uninstallString = $uninstallString + ' /qn'
                    }
                }
                else
                {
                    $parts = $uninstallString -split '\.exe', 2
                    $exe = $parts[0].Trim('"') + '.exe'
                    $arguments = $parts[1].Trim('"')
                }
                

                if ($arguments)
                {
                    if ($uninstallArguments)
                    {
                        $arguments = "$uninstallArguments $arguments"
                    }
                    LogWrite "Using arguments found in registry: $exe $arguments"
                    $process = Start-Process "$exe" -ArgumentList $arguments -PassThru -Wait
                    LogWrite $process.ExitCode
                }
                else
                {
                    if (-not $uninstallArguments)
                    {
                        $uninstallArguments = '/S'
                    }
                    LogWrite "No arguments found in registry, using: $exe $uninstallArguments"
                    $process = Start-Process "$exe" -ArgumentList $uninstallArguments -PassThru -Wait
                }

                break
            }
        }
    }

    # If the program is not found
    if (!$uninstallString)
    {
        LogWrite 'Program not found or uninstall information not available in the Registry.'
    }


}