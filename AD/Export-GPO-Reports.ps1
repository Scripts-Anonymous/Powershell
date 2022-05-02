# SCRIPT NAME   Export-GPO-Reports.ps1
# DESCRIPTION   Creates an HTML report for all GPOs in the domain and saves them
# CREATED ON    1/18/22
# CREATED BY    Mike Cress

# Sets the script log location and begins transcript logging
$scriptLog = $MyInvocation.MyCommand.Path -replace '\.ps1$', '.log'
Start-Transcript -Path $scriptLog -Append

# Function for determing the exact date and time
function Get-TimeStamp {
    return (Get-Date).ToString("yyyyMMdd-HHmmss")
}

Write-Output "$(Get-TimeStamp) Begin logging"

# Set GPO export path
$exportPath = "C:\scripts\exports\GPO-Reports"
$exportFolder = "GpoReport-$(Get-TimeStamp)"
Write-Output "$(Get-TimeStamp) Creating export folder $exportPath\$exportFolder"
mkdir $exportPath\$exportFolder

# Get all GPOs
Write-Output "$(Get-TimeStamp) Get all GPOs"
$AllGPOs = Get-GPO -All

# Loop through each GPO and 
foreach ($gpo in $AllGPOS) {
    $gpoName = $gpo.DisplayName
    Write-Output "$(Get-TimeStamp) Generating report for $gpoName"
    Get-GPOReport -Name $gpo.DisplayName -ReportType html -Path $exportPath\$exportFolder\$gpoName.html
}

# Zipping folder
Write-Output "$(Get-TimeStamp) Zipping $exportPath\$exportFolder"
Compress-Archive -Path $exportPath\$exportFolder -DestinationPath "$exportPath\$exportFolder.zip"

# Remove folder once zip is complete
if (Test-Path "$exportPath\$exportFolder.zip") {
    Write-Output "$(Get-TimeStamp) Zip found. $exportPath\$exportFolder.zip"
    Write-Output "$(Get-TimeStamp) Removing original folder after zip"
    Remove-Item $exportPath\$exportFolder -Recurse -Force
} else {
    Write-Output "$(Get-TimeStamp) Zip not found. Keeping unzipped $exportPath\$exportFolder"
}

# Stops transcript logging
Write-Output "$(Get-TimeStamp) End logging"
Stop-Transcript

