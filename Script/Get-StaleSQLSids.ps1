﻿<#
Will need to change lines 5,8,11 to have a list of your SQL servers and switch to the builtin PS functions, the commented lines below 8 and 11 should be sufficient
#>
$data = [System.Collections.ArrayList]@()
$SqlServers = Get-EwaCmdbServer -isDBmssql 1 -NamesOnly

foreach ($srv in $SqlServers) {
    $connections=Get-EwaSqlInstance -Servers $srv #non-ewa equiv: $connections=Get-SqlInstance -inputObject $srv
    try {
        foreach ($connection in $connections){
            $accounts = invoke-ewasql -SQLCommand "select name,sid from sys.server_principals WHERE type = 'U' AND name like 'ADS%'" -SQLServer $connection.ConnectionInfo -Database master -ErrorAction Stop
            #non-ewa equiv: $accounts=Invoke-Sqlcmd -Query "select name,sid from sys.server_principals WHERE type = 'U' AND name like 'ADS%'" -ServerInstance $connection -Database master
            if ($accounts.count -gt 0) {
                foreach ($account in $accounts) {
                    #remove ads\ prefix from the username for the AD SID query
                    $filteredName = $account.name.tolower().replace('ads\','')
                    #convert the binary SID to a string
                    $sql_sid = (New-Object System.Security.Principal.SecurityIdentifier($account.sid,0)).Value
                    #getting the AD SID
                    $objectSID = (Get-ADObject -LDAPFilter "(samaccountname=$filteredName)" -Properties objectSID -ErrorAction Stop).objectSID.value
                    #Assume SID matches, change the message if not
                    $SIDMatch = $True
                    $message='SQL SID matches AD SID'
                    if ($objectSID -ne $sql_sid) {
                        $SIDMatch = $False
                        $message = 'SQL SID does not match AD SID'
                    }
                    #Fill out the object
                    
                    $dataObj = [ordered]@{
                        'Name' = $account.name
                        'Server' = $connection.ConnectionInfo #$connection.DomainInstanceName ?
                        'SQL_SID' = $sql_sid
                        'AD_SID' = $objectSID
                        'Match' = $SIDMatch
                        'Message' = $message
                    }
                    if($null -eq $objectSID){
                        $data.Add($dataObj) | Out-Null
                    }
                    
                }
            }
        Write-Output "Finished user checks for $($connection.ConnectionInfo)"            
        }
            
    } catch {
        $tnc = Test-Netconnection -ComputerName $srv -Port 1433
        if ($tnc.TcpTestSucceeded -eq 'True'){
            Write-Host "Login refused to $srv" -ForegroundColor Red
            $message = 'Login Refused'
        } else {
            Write-Host "Could not establish connection to $srv" -ForegroundColor Red
            $message = "Could not establish connection"
        }
            
        $dataObj=[ordered]@{
            'Name' = ''
            'Server' = $srv
            'SQL_SID' = ''
            'AD_SID' = ''
            'Match' = ''
            'Message' = $message
        }
            
        $data.Add($dataObj) | Out-Null
            
    }
}

$date = get-date -Format yyyy-MM-dd
#send an email here
if ($data -gt 0) {
    #Email processing
    $BodyText =  "No AD object associated with the below SQL logins could be found. Remove the following users if the logins are no longer needed.<br>If connection errors occured they will be listed here as well.<br>"
    $BodyText +=  "This report was generated by C:\TaskCode\Scheduled\Get-SQLSidStaleLogin.ps1<br>Label=EWA-DBA<br>"
    $BodyText += '<br><br><table border=1><th bgcolor="#E0F8FF">Server</th><th bgcolor="#E0F8FF">Name</th><th bgcolor="#E0F8FF">Message</th>'
    $tablecolors = @{0 = '#ffffff';1 = '#cccccc'}

    foreach ($entry in $data) {
    #Headers: Server, Name, Message
        if ($entry.Match -ne $True) {
        $BodyText += "<tr bgcolor=$($tablecolors[$LoopCounter %2])>"
        $BodyText += "<td>$($entry.Server)</td>"
        $BodyText += "<td>$($entry.Name)</td>"
        $BodyText += "<td>$($entry.Message)</td>"
        $BodyText += "</tr>"
        }

    }
    $emailOpts = @{
        To ='' #your email here
        From = 'noreply@iu.edu'
        SMTPServer = 'mail-relay.iu.edu'
        Subject = 'SQL Login Audit'
        Body = $BodyText

        
    }
    Send-MailMessage @emailOpts -BodyAsHtml -UseSsl
}