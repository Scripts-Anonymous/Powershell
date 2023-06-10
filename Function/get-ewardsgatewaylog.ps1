Function Get-EwaRdsGatewayLog{
    <#
        .Synopsis
            Returns the log of the RDS Gateway
        .Description
            Takes a specific amount of time and returns all log entries from that time frame
        .Parameter TimeAmount
            Int value greater than 0 of how much time to get logs start time from. Defaults to 2
        .Parameter TimeInterval
            Validate set: Days, hours, Minutes, or seconds. The time type to pair with TimeAmount. Defaults to hours
        .Parameter Username
            username to filter on
        .Parameter Environment
            Environment to pull logs from
        .Parameter Log
            Which log source to pull, Application,Microsoft-Windows-TerminalServices-Gateway/Operational, or All to return both
        .Example
            Get-EwaRdsGatewayLog -TimeAmount 4 -TimeInterval seconds -username zrose
        .Example
            Get-EwaRdsGatewayLog
        .Notes
        References specific EWA computers
#>
    Param(
    [CmdletBinding ()]
    [Parameter(Position=1)][ValidateScript({$_ -gt 0})][int]$TimeAmount=2,
    [Parameter(Position=2)][ValidateSet('Days','Hours','Minutes','Seconds')][string]$TimeInterval='Hours',
    [Parameter(Position=3)][ValidateSet('legacyGW','adminGW')][string]$Environment='legacyGW',
    [Parameter(Position=4)][ValidateSet('Microsoft-Windows-TerminalServices-Gateway/Operational','Application','All')][string]$Log='All',
    [Parameter(Position=5)][string]$Username
    )

    Switch ($Environment) {
        'legacyGW' {$ComputerName=@('super-secret-computer-names')} #just an array of computer names
        'adminGW' {$ComputerName=@('super-secret-computer-names')} #just an array of computer names
    }

    Switch ($TimeInterval) {
        'Days' {$StartTime = $((GET-DATE).AddDays(-$TimeAmount))}
        'Hours' {$StartTime = $((GET-DATE).AddHours(-$TimeAmount))}
        'Minutes' {$StartTime = $((GET-DATE).AddMinutes(-$TimeAmount))}
        'Seconds' {$StartTime = $((GET-DATE).AddSeconds(-$TimeAmount))}
    }

    Write-Verbose "Start time for Log is $StartTime"
    foreach ($computer in $ComputerName) {
        if ($Log -eq 'Application') {
            Get-WinEvent -ComputerName $computer -FilterHashtable @{LogName=$Log;ProviderName='Duo Security'; StartTime=$StartTime} -ErrorAction SilentlyContinue | Where-Object {$_.Properties.value -like "*$($username)*"} | Select-Object -Property TimeCreated,Id,LevelDisplayName,@{Name='Message' ; Expression = {$_.properties.value}},@{Name='Computer' ; Expression = {$_.MachineName}}
        } elseif ($Log -eq 'Microsoft-Windows-TerminalServices-Gateway/Operational') {
            Get-WinEvent -ComputerName $computer -FilterHashTable @{LogName=$Log; StartTime=$StartTime} -ErrorAction SilentlyContinue | Where-Object { $_.Message -like "*$($Username)*"}
        } elseif ($Log -eq 'All') {
            Get-WinEvent -ComputerName $computer -FilterHashTable @{LogName='Microsoft-Windows-TerminalServices-Gateway/Operational'; StartTime=$StartTime} -ErrorAction SilentlyContinue | Where-Object { $_.Message -like "*$($Username)*"}
            Get-WinEvent -ComputerName $computer -FilterHashtable @{LogName='Application';ProviderName='Duo Security'; StartTime=$StartTime} -ErrorAction SilentlyContinue | Where-Object {$_.Properties.value -like "*$($username)*"} | Select-Object -Property TimeCreated,Id,LevelDisplayName,@{Name='Message' ; Expression = {$_.properties.value}},@{Name='Computer' ; Expression = {$_.MachineName}}
        }
    }
}