	
function Add-CQUser
{
	<#
	.SYNOPSIS
		Add a user to cq.
	.DESCRIPTION
		Creates an user on the cq instance.
	.PARAMETER userID
		Users ID
	.PARAMETER password
		Users new password
	.PARAMETER email
		Users email address
	.PARAMETER password
		Users new password
	.PARAMETER firstname
		Users firstname
	.PARAMETER lastname
		Users lastname
	.PARAMETER userFolder
		Folder to store the user. 
		E.g. test stores the user under /home/users/test
	.PARAMETER cqObject
		Object with the data of the cq instance.
	.EXAMPLE
		[ps] c:\foo> Add-CQUser -userID "test" -password "test" -email "jan.stettler@axpo.com" -givenName "GivenName" -familyName "FamilyName" -userFolder test -cqObject $cqObject
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[Parameter(Mandatory=$True)]
		[String]$userID,
	
		[Parameter(Mandatory=$True)]
		[String]$password,
	
		[Parameter(Mandatory=$True)]
		[String]$email,
	
		[Parameter(Mandatory=$False)]
		[String]$firstname = "",
	
		[Parameter(Mandatory=$False)]
		[String]$lastname = "",
	
		[Parameter(Mandatory=$False)]
		[String]$userFolder = "",
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	
	$dataValues = @("_charset_=utf-8",
		":status=browser",
		"rep:userId=${userID}",
		"rep:password=${password}",
		"givenName=${givenName}",
		"familyName=${familyName}",
		"email=${email}",
		"intermediatePath=$userFolder"
	)
	$data = ConcatData $dataValues
	
	doCURL $cqObject.authorizables $cqObject.auth $data
}

function Add-CQGroup
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$True)]
		[String]$groupName,
	
		[Parameter(Mandatory=$False)]
		[String]$givenName = "",
	
		[Parameter(Mandatory=$False)]
		[String]$aboutMe = "",
	
		[Parameter(Mandatory=$False)]
		[String]$groupFolder = "",
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	
	$dataValues = @("_charset_=utf-8",
		":status=browser",
		"groupName=${groupName}",
		"givenName=${givenName}",
		"aboutMe=${aboutMe}",
		"intermediatePath=${groupFolder}"
	)
	$data = ConcatData $dataValues
	
	doCURL $cqObject.authorizables $cqObject.auth $data
	
	$group = New-Object psobject -property @{
		groupName=${groupName} ;
		givenName=${givenName};
		aboutMe=${aboutMe};
		path="/home/groups/${groupFolder}";
	}
	return $group | Select groupName, givenName, aboutMe, path
}

function Add-CQMemberToGroup
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$True)]
		[String]$groupPath,
	
		[Parameter(Mandatory=$True)]
		[Array]$memberEntries,
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	
	$url = $cqObject.url+"$groupPath"
	
	$dataValues = @("_charset_=utf-8",
		"memberAction=memberOf"
	)
	$data = ConcatData $dataValues
	$data = $data + "&memberEntry=" + [system.String]::Join("&memberEntry=", $memberEntries)
	
	doCURL $url $cqObject.auth $data
}

function Set-CQMembersFromGroup
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$True)]
		[String]$groupPath,
	
		[Parameter(Mandatory=$True)]
		[Array]$memberEntries,
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	
	$url = $cqObject.url+"$groupPath"
	
	$dataValues = @("_charset_=utf-8",
		"memberAction=members"
	)
	$data = ConcatData $dataValues
	$data = $data + "&memberEntry=" + [system.String]::Join("&memberEntry=", $memberEntries)
	
	doCURL $url $cqObject.auth $data
}

function Remove-CQMemberFromGroup
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$True)]
		[String]$groupId,
	
		[Parameter(Mandatory=$True)]
		[Array]$memberId2Remove,
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	
    $url = $cqObject.authorizablesJson
    
    $groupPath = ""
    $json = CURL -s -f -u $cqObject.auth $url

    $result = $json | ConvertFrom-Json
    $memberOf = @()
    foreach ($obj in $result.authorizables) {
        if($obj.id -eq $groupId) {
            $groupPath = $obj.home
            foreach ($member in $obj.members) {
                if($member.id -ne $memberId2Remove){
                    $memberOf += $member.id
                }
            }
        }
    }

    if($groupPath -ne ""){
        if ( $PSCmdlet.ShouldProcess("Remove [$memberOf] from [$groupPath]") ) {
            Set-CQMembersFromGroup $groupPath $memberOf -cq $cqObject
        }
    }
}

function Add-CQRights
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$True)]
		[String]$authorizableId,
	
		[Parameter(Mandatory=$True)]
		[String]$path,
	
		[Parameter(Mandatory=$False)]
		[String]$read = "false",
	
		[Parameter(Mandatory=$False)]
		[String]$modify = "false",
	
		[Parameter(Mandatory=$False)]
		[String]$create = "false",
	
		[Parameter(Mandatory=$False)]
		[String]$delete = "false",
	
		[Parameter(Mandatory=$False)]
		[String]$acl_read = "false",
	
		[Parameter(Mandatory=$False)]
		[String]$acl_edit = "false",
	
		[Parameter(Mandatory=$False)]
		[String]$replicate = "false",
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	
	$rightData = @("path:{$path}",
		"read:${read}",
		"modify:${modify}",
		"create:${create}",
		"delete:${delete}",
		"acl_read:${acl_read}",
		"acl_edit:${acl_edit}",
		"replicate:${replicate}"
	)
	$changelog = ConcatData $rightData ","
	
	$dataValues = @("authorizableId=$authorizableId",
		"changelog=$changelog"
	)
	
	$data = ConcatData $dataValues
	
	doCURL $cqObject.cqactions $cqObject.auth $data

    $rights = New-Object psobject -property @{
		authorizableId=${authorizableId};
		path=${path};
		read=${read};
		modify=${modify};
		create=${create};
		delete=${delete};
		acl_read=${acl_read};
		acl_edit=${acl_edit};
		replicate=${replicate};
	}
	return $rights | Select authorizableId, path, read, modify, create, delete, acl_read, acl_edit, replicate
}

function Add-CQFullRights
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
	
		[Parameter(Mandatory=$True)]
		[String]$authorizableId,
	
		[Parameter(Mandatory=$True)]
		[String]$path,
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	
	Add-CQRights -authorizableId $authorizableId -path $path -read $True -modify $True -create $True -delete $True -acl_read $True -acl_edit $True -replicate $True -cqObject $cqObject
}

function Add-CQGroupWithRights
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[Parameter(Mandatory=$True)]
		[String]$mandantName,
	
		[Parameter(Mandatory=$True)]
		[String]$groupName,
	
		[Parameter(Mandatory=$False)]
		[String]$givenName = "",
	
		[Parameter(Mandatory=$False)]
		[String]$aboutMe = "",
	
		[Parameter(Mandatory=$False)]
		[Array]$memberOf = @(),
	
		[Parameter(Mandatory=$False)]
		[Array]$contentPaths = @(),
	
		[Parameter(Mandatory=$False)]
		[boolean]$addFullRight = $False,
	
		[Parameter(Mandatory=$True)]
		[Alias("cq")]
		[PSObject]$cqObject
	)
	
	Add-CQGroup -groupName $groupName -givenName $givenName -groupFolder ${mandantName} -cq $cqObject
	if($memberOf.count -gt 0)
	{
		Add-CQMemberToGroup "/home/groups/${mandantName}/$groupName" $memberOf -cq $cqObject
	}
	foreach ($contentPath in $contentPaths)
	{
		if($addFullRight)
		{
			Add-CQFullRights -authorizableId "$groupName" -path $contentPath -cq $cqObject
		} else {
			Add-CQRights -authorizableId "$groupName" -path $contentPath -read $True -cq $cqObject
		}
	}
}