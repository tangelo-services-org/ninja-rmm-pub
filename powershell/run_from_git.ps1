


function RunFromGit
{
    param (
        [Parameter(Mandatory = $true)][string]$script, # Path of file in github repo
        $outfile, # File to execute (probably same as above sans dirs)
        $automation_name, # Used for temp dir names
        [string]$github_api_url = 'https://api.github.com/repos/tangelo-services-org/ninja-rmm/contents', # If you are using a proxy change this
        [string]$github_raw_url = 'https://raw.githubusercontent.com/tangelo-services-org', # If you are using a proxy change this
        [bool]$load_helpers = $true,
        [bool]$user_mode = $false, # If running as logged on user instead of system user, will change working dir to $env:LOCALAPPDATA
        [string]$pub_branch = 'main' # used to swap to different test branches if you want
    )

    $prev_cwd = Get-Location

    if ($load_helpers)
    {
        # If you want to add more helpers, include their names here and upload them to the 
        # powershell/helpers/ folder for the public github repo
        $helper_files = @('create_shortcut.ps1', 'check_installed.ps1', 'set_env_var.ps1', 'set_reg_key.ps1', 'uninstall_program.ps1', 'log_write.ps1')
        $base_url = "$github_raw_url/ninja-rmm-pub/$pub_branch/powershell/helpers"

        foreach ($file in $helper_files)
        {
            Write-Host "Sourcing $file..."
            . ([Scriptblock]::Create((Invoke-WebRequest -Uri "$base_url/$file" -UseBasicParsing).Content))
        }
    }

    
    # Preconfigured variables:
    if ($user_mode)
    {
        $ninja_dir = "$env:LOCALAPPDATA\Temp" # In usermode ProgramData is not writeable by most users
    }
    else
    {
        $ninja_dir = 'C:\ProgramData\NinjaRMMAgent' # Otherwise use this dir
    }

    # Get the install script from github
    # Start by getting the PAT from S3 to access our private repo
    LogWrite 'Getting personal access token from S3...'
    # pat URL encoded with b64 here just to avoid getting grabbed by scrapers
    $pat_url_b64 = 'aHR0cHM6Ly9taW5pby50YW5nZWxvLmNvbS90YW5nZWxvLW5pbmphLXJlcG8vbmluamFfcm1tX2dpdGh1Yi5wYXQ='
    $pat_url = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($pat_url_b64))
    $pat = Invoke-WebRequest -Uri $pat_url -UseBasicParsing | Select-Object -ExpandProperty Content
    $pat = [Text.Encoding]::UTF8.GetString($pat)

    # Check whether we are getting a file or a folder
    $headers = @{
        'Accept'               = 'application/vnd.github.v3.object'
        'Authorization'        = "Bearer $pat"
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    $response = Invoke-WebRequest -Uri "$github_api_url/$([system.uri]::EscapeDataString($script))" -UseBasicParsing -Headers $headers | ConvertFrom-Json

    $script_list = @() # Treat as an array even if we only end up with one script at a time

    if ($response.type -eq 'dir')
    {
        # If we get a directory, we will want to download and run every script within it
        foreach ($entry in $response.entries)
        {
            $script_list += $entry.path
        }
    }
    elseif ($response.type -eq 'file')
    {
        $script_list += $response.path
    } 

    # Object for holding scripts and their results
    $script_results = @()

    foreach ($script in $script_list)
    {
        
        $outfile = Split-Path -Path $script -Leaf
        $automation_name = Format-InvalidPathCharacters -path $outfile
        # Set up temp dirs
        New-Item -ItemType Directory "$ninja_dir\$automation_name" -Force | Out-Null
        Set-Location "$ninja_dir\$automation_name"
        # Download url
        $headers = @{
            'Accept'               = 'application/vnd.github.v3.raw'
            'Authorization'        = "Bearer $pat"
            'X-GitHub-Api-Version' = '2022-11-28'
        }
        if ($pat -like 'github_pat*')
        {
            LogWrite 'Got personal access token'
        }
        else
        {
            LogWrite 'Did not get personal access token'
        }

        # Now we have the PAT, request the file from the repo
        LogWrite "Getting $script from github..."
        Invoke-WebRequest -Uri "$github_api_url/$([system.uri]::EscapeDataString($script))" -Headers $headers -OutFile $outfile -UseBasicParsing
        if (Test-Path $outfile)
        {
            LogWrite "$outfile downloaded successfully"
        }
        else
        {
            LogWrite "$outfile not downloaded"
        }

        # We've got the script, now to run it...
        $process_error = $false
        try
        {
            LogWrite "Running $outfile ..." -writehost $true
            & ".\$outfile" 2>&1 | Out-String
            $result = $LASTEXITCODE
            LogWrite "$outfile done, cleaning up..." -writehost $true
        }
        catch
        {
            # We will throw any errors later, after we have cleaned up dirs
            $process_error = $_.Exception 
        }

        $script_results += @{
            'script' = $script
            'result' = "$result $process_error"
        }
        
       

        # Clean up 
        Set-Location "$ninja_dir"
        Remove-Item "$ninja_dir\$automation_name" -Force -Recurse
        if (Test-Path "$ninja_dir\$automation_name")
        {
            LogWrite "Failed to clean up $ninja_dir\$automation_name"
        }
        else
        {
            LogWrite "Cleaned up $ninja_dir\$automation_name"
        }
        LogWrite $result -writehost $true
    }

    Write-Host $script_results

    Set-Location $prev_cwd
    if ($process_error)
    {
        throw $process_error
    }
    else
    {
        return $result
    }
}


function Format-InvalidPathCharacters
{
    param (
        [string]$path
    )

    # Define a regex pattern to match non-standard characters
    $invalidCharsPattern = '[\\/:*?"<>|]'

    # Replace non-standard characters with an underscore
    $escapedPath = [regex]::Replace($path, $invalidCharsPattern, '_')

    return $escapedPath
}

if (-not $env:NINJA_LOG_FILE)
{
    $Logfile = 'C:\ProgramData\NinjaRMMAgent\run_from_git_logs.txt'

    if (-not (Test-Path $LogFile))
    {
        New-Item $Logfile
    }
}


