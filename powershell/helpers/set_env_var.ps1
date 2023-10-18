function SetEnvVar
{
    param (
        [Parameter(Mandatory = $true)][string]$key,
        [Parameter(Mandatory = $true)][string]$value
    )

    Write-Host "Setting env var $variable to $value"
    [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Machine)
    
}