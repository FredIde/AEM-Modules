
function Add-CQTag
{
	<#
    .SYNOPSIS
    	Add a cq tag.
    .DESCRIPTION
    	This method creates a cq:Tag in a cq instance.
    .PARAMETER tagTitle
        Title of the new tag.
    .PARAMETER tagName
        Name of the new tag.
    .PARAMETER description
        Description of the new tag.
	.PARAMETER cqObject
        Object with the data of the cq instance.
		
    .EXAMPLE
		[ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
		[ps] c:\foo> Add-CQSlingFolder -tagTitle "myTag" -cq $cqObject

	.EXAMPLE
		[ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
		[ps] c:\foo> Add-CQSlingFolder -tagTitle "myTag" -tagName "myTagname" -cq $cqObject
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[Parameter(Mandatory=$true)]
		[String]$tagTitle,
	
		[Parameter(Mandatory=$false)]
		[String]$tagName,
	
		[Parameter(Mandatory=$false)]
		[String]$description,
	
		[Parameter(Mandatory=$true)]
		[alias("cq")]
		[PSObject]$cqObject
	)
	
	$dataValues = @("_charset_=utf-8",
		":status=browser",
		"cmd=createTag",
		"jcr:title=$tagTitle",
		"tag=$tagName",
		"jcr:description=$description"
	)
	$data = ConcatData $dataValues
	
	doCURL $cqObject.tagCommand $cqObject.auth $data
	
	$tag = New-Object psobject -property @{
		title=$tagTitle;
		tag=$tagName;
		description=$description;
	}
	return $tag | Select title, tag, description
}