$keys=get-tlsciphersuite
foreach($key in $keys){
	write-host $key.Name
}