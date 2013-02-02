

function Set-CQContent
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$true)]
		[String]$nodePath,
	
		[Parameter(Mandatory=$true)]
		[String]$itemName,
	
		[Parameter(Mandatory=$false)]
		[String]$itemValue,
	
		[Parameter(Mandatory=$true)]
		[alias("cq")]
		[PSObject]$cqObject
	)
	
	$url = $cqObject.url+"$nodePath"
	
	$dataValue = @("$itemName=$itemValue" )
	$data = ConcatData $dataValue
	
	doCURL $url $cqObject.auth $data
}
