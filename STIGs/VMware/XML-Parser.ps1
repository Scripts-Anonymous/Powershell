$Path="/Users/jeff/Documents/GitHub/Powershell/STIGs/Template_Answer_files/VMware_vSphere_6.7_V1R1/Template-VirtualMachine.ckl"
$File = [xml](Get-Content $Path)
$File.SelectNodes("/Checklist/Asset/Host_Name") | % { 
    $_."#text" = $_."#text".Replace("TestMachine", "Machine") 
}
$File.Save($Path)

<#
$element =  $xml.Checklist.Asset.Host_Name

using xml
$xml = [xml](Get-Content .\test.xml)
$xml.SelectNodes("//command") | % { 
    $_."#text" = $_."#text".Replace("C:\Prog\Laun.jar", "C:\Prog32\folder\test.jar") 
    }

$xml.Save("C:\Users\graimer\Desktop\test.xml")
#>
