#Requires -Version 2.0

DATA aliases {
	convertfrom-stringdata @"
Get-WIFileHash = Get-MSIFileHash
Get-WIFileType = Get-MSIFileType
Get-WIPatchInfo = Get-MSIPatchInfo
Get-WIProductInfo = Get-MSIProductInfo
Get-WIRelatedProductInfo = Get-MSIRelatedProductInfo
"@
}

$aliases.GetEnumerator() | foreach-object -process {
	new-alias -name $_.name -value $_.value -option ReadOnly -force
}

function Get-WISharedComponentInfo {

# .ExternalHelp Microsoft.WindowsInstaller.PowerShell.dll-Help.xml

	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[ValidateNotNullOrEmpty()]
		[Microsoft.WindowsInstaller.PowerShell.ValidateGuid()]
		[string[]] $ComponentCode,
		
		[Parameter(Position = 1)]
		[ValidateRange(2, 2147483647)]
		[int] $Count = 2
	)
	
	end {
		$getcomponents = { get-wicomponentinfo }
		if ($ComponentCode) {
			$getcomponents = { get-wicomponentinfo -componentcode $ComponentCode }
		}
		& $getcomponents | group-object -property ComponentCode | where-object { $_.Count -ge $Count } `
			| select-object -expand Group | sort-object -property ComponentCode, ProductCode
	}
}

export-modulemember -alias * -function *

# Update the usage information for this module if installed.
[Microsoft.WindowsInstaller.PowerShell.Module]::Use()