	
function Start-CQBackup
{
	[CmdletBinding(SupportsShouldProcess=$True)]
	param (
		[Parameter(Mandatory=$False)]
		[String]$userID,
	
		[Parameter(Mandatory=$False)]
		[String]$password,
	
		[Parameter(Mandatory=$False)]
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
	
	$dataValues = @("action=add",
		"zipFileName=backup.zip"
	)
	$data = ConcatData $dataValues
	
	doCURL $cqObject.backup $cqObject.auth $data
    #CURL -b $CQ.loginFile -f -o $CQ.progressFile --data $data $url
	# curl -b $CQ.loginFile -f -o target.zip "http://localhost:7402/crx/config/backupDownload.jsp?action=download&backup=/Users/abc/backup.zip"
    #rm login.txt
    #rm progress.txt
}

