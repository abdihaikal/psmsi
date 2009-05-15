<#
.Synopsis
	Exports wiki content from cmdlet help to text files.

.Description
	Help content is extracted for each cmdlet to a text file with text formatted for the CodePlex wiki.

.Parameter Path
	A path or paths to the help files.

.Parameter Version
	The version to use in filenames for the wiki.

.Parameter OutDirectory
	The directory where the output files are created.

.Example
	PS> export-help.ps1 -path Microsoft.WindowsInstaller.PowerShell.dll-help.xml

.Link
	get-content
	set-content
#>

#Requires -Version 2.0

param(
	[Parameter(Position=0, Mandatory=$true)]
	[string[]] $Path,

	[Parameter(Position=1)]
	[Version] $Version = "2.0",

	[Parameter(Position=2)]
	[string] $OutDirectory = $([System.IO.Path]::GetTempPath())
)

process {

    $names = @()

	# Get commands from all input paths.
	foreach ($p in $Path)
	{
    	[xml] $doc = get-content $p
    
    	# Select only elements and not the "command" namespace prefix.
    	$nsmgr = new-object -type System.Xml.XmlNamespaceManager $doc.NameTable
    	$nsmgr.AddNamespace("command", "http://schemas.microsoft.com/maml/dev/command/2004/10")
    
    	$doc.helpItems.SelectNodes("command:command", $nsmgr) | foreach-object -begin {
    
    		$xslt = new-object -type System.Xml.Xsl.XslCompiledTransform
    		$xargs = new-object -type System.Xml.Xsl.XsltArgumentList
    		
    		$invocation = $(get-variable MyInvocation -scope 0).Value
    		$stylesheet = join-path $(split-path $invocation.MyCommand.Path) "Help.xslt"
    
    		$xslt.Load($stylesheet);
    
    		$xargs.AddParam("version", "", [string] $Version);
    
    	} -process {
    
    		$reader = new-object -type System.Xml.XmlNodeReader -argumentlist $_
    		$writer = new-object -type System.IO.StringWriter
    
    		$xslt.Transform($reader, $xargs, $writer);
    
    		$page = join-path $OutDirectory $("{1}.v{0}.txt" -f $Version, $_.details.name)
    		$writer.ToString() | set-content -path $page -encoding "UTF8"
    		
    		$names += $_.details.name
    		$page
    	}
	}
    
	# Generate the table of contents
	$names | sort-object | foreach-object -begin {

		$lines = "! Help", "!! Cmdlets"

	} -process {

		$lines += $("* [{1}|{1}.v{0}]" -f $Version, $_)

	} -end {

		$page = join-path $OutDirectory $("Help.v{0}.txt" -f $Version)
		$lines | set-content -path $page -encoding "UTF8"

		$page
	}
}
