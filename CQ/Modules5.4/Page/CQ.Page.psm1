
function Add-CQPage
{
 	<#
    .SYNOPSIS
    	Add a cq page.
    .DESCRIPTION
    	This method creates a new page in a cq instance.
    .PARAMETER title
        Title for the page.
    .PARAMETER label
        Label for the page.
    .PARAMETER parentPath
        Where should the page be stored.
	.PARAMETER template
		Creates the page with this template.
	.PARAMETER cqObject
        Object with the data of the cq instance.
		
    .EXAMPLE
		[ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
		[ps] c:\foo> Add-CQPage -title "My Title" -parentPath "/content" -template "/apps/myapp/components/homepage" -cq $cqObject

	.EXAMPLE
		[ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
		[ps] c:\foo> Add-CQPage -title "My Title" -label "myurllabel" -parentPath "/content/my-title" -template "/apps/myapp/components/contentpage" -cq $cqObject
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[Parameter(Mandatory=$true)]
		[String]$title = "",
	
		[Parameter(Mandatory=$false)]
		[String]$label = "",
	
		[Parameter(Mandatory=$true)]
		[String]$parentPath = "/content",
	
		[Parameter(Mandatory=$true)]
		[string]$template = "",
	
		[Parameter(Mandatory=$true)]
		[alias("cq")]
		[PSObject]$cqObject
	)
	
	$dataValues = @("_charset_=utf-8",
		":status=browser",
		"cmd=createPage",
		"parentPath=$parentPath",
		"title=$title",
		"label=$label",
		"template=$template"
	)
	$data = ConcatData $dataValues
	
	doCURL $cqObject.wcmCommand $cqObject.auth $data
	
	$page = New-Object psobject -property @{
		parentPath=$parentPath;
		title=$title;
		label=$label;
		template=$template;
	}
	return $page | Select parentPath, title, label, template
}
