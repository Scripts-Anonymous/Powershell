$FileSystemWatcher = New-Object System.IO.FileSystemWatcher
$FileSystemWatcher.Path  = "E:\*PATH*\"
Register-ObjectEvent -InputObject $FileSystemWatcher  -EventName Created  -Action{
	$Object  = "{0} was  {1} at {2}" -f $Event.SourceEventArgs.FullPath,
	$Event.SourceEventArgs.ChangeType,
	$Event.TimeGenerated
	$WriteHostParams  = @{
		ForegroundColor = 'Green'
		BackgroundColor =  'Black'
		Object =  $Object
	}
 	Write-Host @WriteHostParams
}