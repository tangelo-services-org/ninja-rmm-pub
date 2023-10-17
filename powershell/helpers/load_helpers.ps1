# Intended for this to be downloaded and run, which will then install the rest 
# of the modules in this folder, if you need to update or add any helpers you
# can add them here without breaking any of the paths other scripts are using

$base_url = 'https://raw.githubusercontent.com/tangelo-services-org/ninja-rmm-pub/main/powershell/helpers'

$helper_files = @('check_installed.ps1')

foreach ($file in $helper_files)
{
    Write-Host "Sourcing $file..."
    . ([Scriptblock]::Create((([System.Text.Encoding]::ASCII).getString((Invoke-WebRequest -Uri "$base_url/$file").Content))))
}