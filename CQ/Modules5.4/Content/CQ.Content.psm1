

function Set-CQContent
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$True)]
		[String]$nodePath,
	
		[Parameter(Mandatory=$True)]
		[String]$itemName,
	
		[Parameter(Mandatory=$False)]
		[String]$itemValue,
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	$url = $cqObject.url+"$nodePath"
	
	$dataValue = @("$itemName=$itemValue" )
	$data = ConcatData $dataValue
    
	doCURL $url $cqObject.auth $data
}
