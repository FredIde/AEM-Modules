Set-StrictMode -Version 2.0

# -----------------------------------------------------------------------
# Displays help usage
# -----------------------------------------------------------------------
function WriteUsage([string]$msg)
{
	$moduleNames = $CQ.ModulesToImport.Keys | Sort

	if ($msg) { Write-Host $msg }
	
	$OFS = ','
	Write-Host @"
 
To load all CQ modules using the default CQ preferences execute: 

    Import-Module CQ

The nested module names are:

$moduleNames

"@
}

# -----------------------------------------------------------------------
# Load nested modules selected by user
# -----------------------------------------------------------------------
$stopWatch = new-object System.Diagnostics.StopWatch
. $PSScriptRoot\CQ.UserPreferences.ps1


$keys = @($CQ.ModulesToImport.Keys)
if ($CQ.ShowModuleLoadDetails) 
{ 
	Write-Host "PowerShell Community Extensions $($CQ.Version)`n"
	$totalModuleLoadTimeMs = 0
	$stopWatch.Reset()
	$stopWatch.Start()
	$keys = @($keys | Sort)
}

foreach ($key in $keys)
{
	if ($CQ.ShowModuleLoadDetails) 
	{
		$stopWatch.Reset()
		$stopWatch.Start()
		Write-Host " $key $(' ' * (20 - $key.length))[ " -NoNewline
	}
	
	if (!$CQ.ModulesToImport.$key) 
	{ 	
		# Not selected for loading by user 
		if ($CQ.ShowModuleLoadDetails) 
		{	
			Write-Host "Skipped" -nonew
		}		
	}
	else 
	{
	    $subModuleBasePath = "$PSScriptRoot\Modules\{0}\CQ.{0}" -f $key
	    
		# Check for PSD1 first
		$path = "$subModuleBasePath.psd1"
		if (!(Test-Path -PathType Leaf $path)) 
		{
			# Assume PSM1 only
			$path = "$subModuleBasePath.psm1"
			if (!(Test-Path -PathType Leaf $path))
			{
				# Missing/invalid module
				if ($CQ.ShowModuleLoadDetails) 
				{
					Write-Host "Module $path is missing ]"
				} 
				else 
				{
					Write-Warning "Module $path is missing."
				}			
				continue
			}
		}
		
		try 
		{
			# Don't complain about non-standard verbs with nested imports but
			# we will still have one complaint for the final global scope import
			Import-Module $path -DisableNameChecking 
			
			if ($CQ.ShowModuleLoadDetails) 
			{ 
				$stopWatch.Stop()
				$totalModuleLoadTimeMs += $stopWatch.ElapsedMilliseconds
				$loadTimeMsg = "Loaded in {0,4} ms" -f $stopWatch.ElapsedMilliseconds
				Write-Host $loadTimeMsg -nonew
			}
		} 
		catch 
		{
			# Problem in module
			if ($CQ.ShowModuleLoadDetails) 
			{
				Write-Host "Module $key load error: $_" -nonew 
			} 
			else 
			{
				Write-Warning "Module $key load error: $_"
			}
		}		
	} 
	
	if ($CQ.ShowModuleLoadDetails) 
	{ 
		Write-Host " ]" 
	}
}

Export-ModuleMember -Alias * -Function * -Cmdlet *


function Get-CQHost
{
 <#
    .SYNOPSIS
    	Create a cq host object.
    .DESCRIPTION
    	You can create a cq object with several properties. This object centralizes a lot of properties and default values that
		will be used by other functions.
    .PARAMETER cqHost
        Host of the cq instance. Default value is localhost
    .PARAMETER cqPort
        Port of the cq instance. Default value is 4502
    .PARAMETER cqUser
        User to connect with. Default value is admin
    .PARAMETER cqHost
        Password to connect with. Default value is admin
    .EXAMPLE
        [ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
    #>
	[CmdletBinding()]
	Param(
	
		[Parameter(Mandatory=$false)]
		[String]$cqHost = "localhost",
	
		[Parameter(Mandatory=$false)]
		[String]$cqPort = "4502",
	
		[Parameter(Mandatory=$false)]
		[String]$cqUser = "admin",
	
		[Parameter(Mandatory=$false)]
		[String]$cqPassword = "admin"
	)
	$obj = New-Object PSObject -property @{
		host=$cqHost;
		port=$cqPort;
		user=$cqUser;
		password=$cqPassword;
		url="${cqHost}:${cqPort}";
		auth="${cqUser}:${cqPassword}";
		wcmCommand="${cqHost}:${cqPort}/bin/wcmcommand";
		tagCommand="${cqHost}:${cqPort}/bin/tagcommand";
		authorizables="${cqHost}:${cqPort}/libs/cq/security/authorizables/POST";
		cqactions="${cqHost}:${cqPort}/.cqactions.html";
	}
	Return $obj
}

function ConcatData
{
 	<#
    .SYNOPSIS
    	Concat an array to a string.
    .DESCRIPTION
    	Concat an array to one single string with a specified delimiter.
		This will be used to concatenate POST parameters to one string.
    .PARAMETER data
        Data array to join.
    .PARAMETER delim
        Delimiter to join the data together. Default value is &
    .EXAMPLE
        [ps] c:\foo> $data = @("_charset_=utf-8",
                            ":status=browser",
                            "cmd=createPage",
                            "parentPath=$parentPath",
                            "title=$title",
                            "label=$label",
                            "template=$template"
                            )
        [ps] c:\foo> $data = ConcatData $data
		_charset_=utf-8&:status=browser&cmd=createPage&parentPath=&title=&label=&template=

    #>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[array]$data,
	
		[Parameter(Mandatory=$false)]
		[String]$delim = "&"
	)
	return [system.String]::Join($delim, $data)
}

function doCURL
{
 	<#
    .SYNOPSIS
    	Does the POST request to the wcms instance.
    .DESCRIPTION
    	This method makes the CURL request to the wmcs instance. It need the url to POST the data and the authentication properties.
    .PARAMETER url
        URl to make the POST
    .PARAMETER auth
        Authentication information for the wcms instance. Default value is admin:admin
    .PARAMETER data
        Data to POST
    .EXAMPLE
		[ps] c:\foo> $cqobject = Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
		[ps] c:\foo> $dataValues = @("_charset_=utf-8",
									":status=browser",
									"cmd=createPage",
									"parentPath=$parentPath",
									"title=$title",
									"label=$label",
									"template=$template"
									)
    	[ps] c:\foo> $data = ConcatData $dataValues
        [ps] c:\foo> doCURL $cqObject.wcmCommand $cqObject.auth $data
    #>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[Parameter(Mandatory=$true)]
		[string]$url,
	
		[Parameter(Mandatory=$true)]
		[string]$auth,
	
		[Parameter(Mandatory=$true)]
		[String]$data
	)
	if ( $PSCmdlet.ShouldProcess("doCurl to $url with data $data") ) {
		CURL -s -f -u $auth --data $data $url -D "header.txt" -o "temp.txt"
	}
}
