<# STIG_Extraction
  -----------------------------------------------------------------------------------------
    Author: 
	Jeff Allen
	Sr. Systems Administrator
	Version: 2021-07-26
    Notes:
        Do NOT include quotes when entering the input path.
        Output will be "C:\adm\$STIGNAME.txt"
#>

# Parameter definiations
param(
	[parameter(Mandatory=$false)]
	[String]$InputPath=(Read-Host "What STIG file would you like extracted? Do NOT include Quotes")
)

# Enable XML parsing on input file
[xml]$xmlInputs=Get-Content -Path $InputPath

# Extract Benchmark Name
$BenchmarkName=$xmlInputs.Benchmark.id

# Write output file
$OutputFile="C:\*PATH*\$BenchmarkName.txt"
New-Item $OutputFile

# Extract all V-IDs, Titles, Check-Content
$vIDs=$xmlInputs.Benchmark.Group
ForEach ($vID in $vIDs){
    Add-Content $OutputFile $vID.id
    Add-Content $OutputFile $vID.Rule.id
    Add-Content $OutputFile $vID.Rule.title
    Add-Content $OutputFile $vID.Rule.check."check-content"
    Add-Content $OutputFile `n`n`n
}