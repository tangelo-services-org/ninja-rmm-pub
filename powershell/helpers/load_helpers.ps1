# Intended for this to be downloaded and run, which will then install the rest 
# of the modules in this folder, if you need to update or add any helpers you
# can add them here without breaking any of the paths other scripts are using
#
# Intended to be called like: 
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/tangelo-services-org/ninja-rmm-pub/main/powershell/helpers/load_helpers.ps1'))
# 
# To add more helpers, put the files in this helpers/ folder and add their names to 
# $helper_files

$base_url = 'https://raw.githubusercontent.com/tangelo-services-org/ninja-rmm-pub/main/powershell/helpers'

$helper_files = @('check_installed.ps1')

foreach ($file in $helper_files)
{
    Write-Host "Sourcing $file..."
    . ([Scriptblock]::Create((Invoke-WebRequest -Uri "$base_url/$file" -UseBasicParsing).Content))
}