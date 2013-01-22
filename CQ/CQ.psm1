<#
.SYNOPSIS
   Several functions for working with CQ5.4
.DESCRIPTION
   
.PARAMETER <ParamName>
   
.EXAMPLE
   
#>
Function Get-CQHost
{
    <#
    .SYNOPSIS
    Create a cq host object.
    .DESCRIPTION
    You can create a cq object with several properties.
    .PARAMETER cqHost
        Host of the cq instance. Default value is localhost
    .PARAMETER cqPort
        Port of the cq instance. Default value is 4502
    .PARAMETER cqUser
        User to connect with. Default value is admin
    .PARAMETER cqHost
        Password to connect with. Default value is admin
    .EXAMPLE
        [ps] c:\foo> Get-CQHost -cqHost "myserver" -cqPort "5000" -cqUser "john" -cqPassword "deer"
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
    concat an array to one single string with a specified delimiter.
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$url,

        [Parameter(Mandatory=$true)]
        [string]$auth,
        
        [Parameter(Mandatory=$true)]
        [String]$data
    )
    CURL -s -f -u $auth --data $data $url -D "header.txt" -o "temp.txt"
}

Function Add-CQPage
{
    [CmdletBinding()]
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

Function Add-CQSlingFolder
{
    [CmdletBinding()]
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

Function Add-CQTag
{
    [CmdletBinding()]
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

Function Add-CQUser
{
    <#
    .SYNOPSIS
    Concat an array to a string.
    .DESCRIPTION
    concat an array to one single string with a specified delimiter.
    .PARAMETER userId
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
        folder to store the user. E.g. test stores the user under /home/users/test
    .PARAMETER cqObject
        Object with the data of the cq instance
    .EXAMPLE
        [ps] c:\foo> Add-CQUser -userID "test" -password "test" -email "jan.stettler@axpo.com" -givenName "GivenName" -familyName "FamilyName" -userFolder test -cqOb
ject $cqObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$userID,
        
        [Parameter(Mandatory=$true)]
        [String]$password,

        [Parameter(Mandatory=$true)]
        [String]$email,

        [Parameter(Mandatory=$false)]
        [String]$firstname = "",
        
        [Parameter(Mandatory=$false)]
        [String]$lastname = "",
        
        [Parameter(Mandatory=$false)]
        [String]$userFolder = "",
        
        [Parameter(Mandatory=$true)]
        [alias("cq")]
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
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [String]$groupName,
        
        [Parameter(Mandatory=$false)]
        [String]$givenName = "",
        
        [Parameter(Mandatory=$false)]
        [String]$aboutMe = "",
        
        [Parameter(Mandatory=$false)]
        [String]$groupFolder = "",
        
        [Parameter(Mandatory=$true)]
        [alias("cq")]
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
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [String]$groupPath,
        
        [Parameter(Mandatory=$true)]
        [array]$memberEntries,
        
        [Parameter(Mandatory=$true)]
        [alias("cq")]
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

Function Add-CQRights
{
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [String]$authorizableId,
        
        [Parameter(Mandatory=$true)]
        [String]$path,
        
        [Parameter(Mandatory=$false)]
        [String]$read = "false",

        [Parameter(Mandatory=$false)]
        [String]$modify = "false",

        [Parameter(Mandatory=$false)]
        [String]$create = "false",
        
        [Parameter(Mandatory=$false)]
        [String]$delete = "false",
        
        [Parameter(Mandatory=$false)]
        [String]$acl_read = "false",
        
        [Parameter(Mandatory=$false)]
        [String]$acl_edit = "false",
        
        [Parameter(Mandatory=$false)]
        [String]$replicate = "false",
        
        [Parameter(Mandatory=$true)]
        [alias("cq")]
        [PSObject]$cqObject
    )

    $rightData = @("path:$path",
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
}

Function Add-CQFullRights
{
    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [String]$authorizableId,
        
        [Parameter(Mandatory=$true)]
        [String]$path,
        
        [Parameter(Mandatory=$true)]
        [alias("cq")]
        [PSObject]$cqObject
    )

	Add-CQRights -authorizableId $authorizableId -path $path -read $true  -modify $true -create $true -delete $true -acl_read $true -acl_edit $true -replicate $true -cqObject $cqObject
}

function Add-CQGroupWithRights
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$mandantName,

        [Parameter(Mandatory=$true)]
        [String]$groupName,
        
        [Parameter(Mandatory=$false)]
        [String]$givenName = "",
        
        [Parameter(Mandatory=$false)]
        [String]$aboutMe = "",

        [Parameter(Mandatory=$false)]
        [array]$memberOf = @(),

        [Parameter(Mandatory=$false)]
        [array]$contentPaths = @(),

        [Parameter(Mandatory=$true)]
        [alias("cq")]
        [PSObject]$cqObject
    )

    Add-CQGroup -groupName $groupName -givenName $givenName -groupFolder ${mandantName} -cq $cqObject
    Add-CQMemberToGroup "/home/groups/${mandantName}/$groupName" $memberOf -cq $cqObject
    foreach ($contentPath in $contentPaths)
    {
        Add-CQRights -authorizableId "$groupName" -path $contentPath -read $true -cq $cqObject
    }
}

function Set-CQContent
{
    [CmdletBinding()]
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