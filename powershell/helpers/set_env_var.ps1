function SetEnvVar
{
    param (
        [Parameter(Mandatory = $true)][string]$key,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$value
    )
    if ($value -eq '' )
    {
        LogWrite "Deleting env var $key"
    }
    else
    {
        LogWrite "Setting env var $key to $value"

    }
    [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Machine)
    
}