# My Powershell script to bootstrap a raw machine
# Should be executed under Windows PowerShell, until PowerShell Core is out of box

Function Get-LatestGitHubRelease(
    [Parameter(Mandatory)]
    [string] $Account,
    [Parameter(Mandatory)]
    [string] $Repository,
    [Parameter(Mandatory)]
    [string] $AssetPattern
) {
    $api = Invoke-WebRequest "https://api.github.com/repos/$Account/$Repository/releases/latest" | ConvertFrom-Json
    $asset = $api.assets | Where-Object name -Like $AssetPattern | Select-Object -First 1
    return $asset.browser_download_url
}

Function DownloadAndAddAppx(
    [Parameter(Mandatory)]
    [string] $Url
) {
    $filename = Split-Path $Url -Leaf
    $tempfile = $env:Temp + '\' + $filename
    Invoke-WebRequest $Url -OutFile $tempfile
    Add-AppPackage $tempfile
}

# Detect PowerShell Version
$ExpectedPSVersion = '5.1'
if ($PSVersionTable.PSVersion -lt $ExpectedPSVersion) {
    Write-Warning "This script is tested under PowerShell $ExpectedPSVersion,
but is currently executed under PowerShell $($PSVersionTable.PSVersion)."
    if ($Host.UI.PromptForChoice('Force running this?', '', ('&Yes', '&No'), 1) -ne 0) {
        exit
    }
}

# Detect PowerShell Version
$ExpectedOSVersion = '10.0.18362'
if ([System.Environment]::OSVersion.Version -lt $ExpectedOSVersion) {
    Write-Warning "This script is tested under Windows $ExpectedOSVersion,
but is currently executed under Windows $([System.Environment]::OSVersion.Version)."
    if ($Host.UI.PromptForChoice('Force running this?', '', ('&Yes', '&No'), 1) -ne 0) {
        exit
    }
}

# Find winget
$WinGet = where.exe 'winget' 2>$null
if ($WinGet) {
    Write-Host -ForegroundColor Green "WinGet found at $WinGet"
}
else {
    Write-Warning 'WinGet not found.'
    if ($Host.UI.PromptForChoice('Install WinGet from GitHub?', '', ('&Yes', '&No'), 1) -ne 0) {
        Write-Warning 'Skipping all dependencies of WinGet.'
    }
    else {
        Get-LatestGitHubRelease 'Microsoft' 'winget-cli' '*.appxbundle' | DownloadAndAddAppx
    }
}

Get-LatestGitHubRelease 'PowerShell' 'PowerShell' '*x64.msix' | DownloadAndAddAppx
