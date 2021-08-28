





New-OSCustomizationSpec -Name 'WindowsServer2016' -FullName 'TestName' -OrgName 'MyCompany' -OSType Windows -ChangeSid -AdminPassword (Read-Host -AsSecureString) -Domain 'NTDOMAIN' -TimeZone 035 -DomainCredentials (Get-Credential) -ProductKey '5555-7777-3333-2222' -AutoLogonCount 1