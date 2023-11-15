function RunFromGit
{
    param (
        [Parameter(Mandatory = $true)][string]$script, # Path of file in github repo
        [Parameter(Mandatory = $true)][string]$outfile, # File to execute (probably same as above sans dirs)
        [Parameter(Mandatory = $true)][string]$automation_name, # Used for temp dir names
        [string]$github_api_url = 'https://api.github.com/repos/tangelo-services-org/ninja-rmm/contents', # If you are using a proxy change this
        [string]$github_raw_url = 'https://raw.githubusercontent.com/tangelo-services-org', # If you are using a proxy change this
        [bool]$load_helpers = $true,
        [bool]$user_mode = $false, # If running as logged on user instead of system user, will change working dir to $env:LOCALAPPDATA
        [string]$pub_branch = 'main' # used to swap to different test branches if you want
    )

    if ($load_helpers)
    {
        # If you want to add more helpers, include their names here and upload them to the 
        # powershell/helpers/ folder for the public github repo
        $helper_files = @('check_installed.ps1', 'set_env_var.ps1', 'set_reg_key.ps1', 'uninstall_program.ps1')
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

    # Set up temp dirs
    New-Item -ItemType Directory "$ninja_dir\$automation_name" -Force
    Set-Location "$ninja_dir\$automation_name"

    # Get the install script from github
    # Start by getting the PAT from S3 to access our private repo
    Write-Host 'Getting personal access token from S3...'
    # pat URL encoded with b64 here just to avoid getting grabbed by scrapers
    $pat_url_b64 = 'aHR0cHM6Ly90YW5nZWxvLW5pbmphLXJlcG8uczMuYXAtc291dGhlYXN0LTIuYW1hem9uYXdzLmNvbS9uaW5qYV9ybW1fZ2l0aHViLnBhdA=='
    $pat_url = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($pat_url_b64))
    $pat = Invoke-WebRequest -Uri $pat_url -UseBasicParsing | Select-Object -ExpandProperty Content
    $pat = [Text.Encoding]::UTF8.GetString($pat)
    $headers = @{
        'Accept'               = 'application/vnd.github.v3.raw'
        'Authorization'        = "Bearer $pat"
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    if ($pat -like 'github_pat*')
    {
        Write-Host 'Got personal access token'
    }
    else
    {
        Write-Host 'Did not get personal access token'
    }

    # Now we have the PAT, request the file from the repo
    Write-Host 'Getting script from github...'
    Invoke-WebRequest -Uri "$github_api_url/$([system.uri]::EscapeDataString($script))" -Headers $headers -OutFile $outfile
    if (Test-Path $outfile)
    {
        Write-Host "$outfile downloaded successfully"
    }
    else
    {
        Write-Host "$outfile not downloaded"
    }

    # We've got the script, now to run it...
    $process_error = $false
    try
    {
        Write-Host "Running $outfile ..."
        & ".\$outfile" 2>&1 | Out-String
        $result = $LASTEXITCODE
        Write-Host "$outfile done, cleaning up..."
    }
    catch
    {
        # We will throw any errors later, after we have cleaned up dirs
        $process_error = $_.Exception 
    }
        
       

    # Clean up 
    Set-Location "$ninja_dir"
    Remove-Item "$ninja_dir\$automation_name" -Force -Recurse
    if (Test-Path "$ninja_dir\$automation_name")
    {
        Write-Host "Failed to clean up $ninja_dir\$automation_name"
    }
    else
    {
        Write-Host "Cleaned up $ninja_dir\$automation_name"
    }

    if ($process_error)
    {
        throw $process_error
    }
    else
    {
        return $result
    }
}



