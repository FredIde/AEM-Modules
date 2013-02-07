
function Add-CQSlingFolder
{
 	<#
    .SYNOPSIS
    	Add a sling folder.
    .DESCRIPTION
    	This method creates a sling:Folder in a cq instance.
    .PARAMETER folderPath
        Path to the new folder.
	.PARAMETER cqObject
        Object with the data of the cq instance.
		
    .EXAMPLE
		[ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
		[ps] c:\foo> Add-CQSlingFolder -folderPath "/apps/myapp/docroot/folder" -cq $cqObject

	.EXAMPLE
		[ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
		[ps] c:\foo> Add-CQSlingFolder -folderPath "/content/dam/myapp/newfolder" -cq $cqObject
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$true)]
		[String]$folderPath,
	
		[Parameter(Mandatory=$true)]
		[alias("cq")]
		[PSObject]$cqObject
	)
	$url = $cqObject.url+"$folderPath"
	
	$dataValues = @("_charset_=utf-8",
		"./jcr:primaryType=sling:OrderedFolder",
		"./jcr:content/jcr:primaryType=nt:unstructured"
	)
	$data = ConcatData $dataValues
	
	doCURL $url $cqObject.auth $data
	
	$folder = New-Object psobject -property @{
		damPath=$folderPath;
	}
	return $folder | Select damPath
}