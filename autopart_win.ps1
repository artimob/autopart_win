<#
	.SYNOPSIS
		Quick and dirty script to automaticaly partition and format new disks presented to a system
		
	.DESCRIPTION
		This PowerShell script is to support automated discovery, mounting and formatting of a new disk devices presented to a Windows OS. Arguments allow to define disk letter and drive label preffix (optional). If no arguments defined then scripts searches for new devices, partitions them and creates NTFS file system, drive letter and labels assigned automatically.
		Tested on: Windows Server 2008 R2 and Windows Server 2012 R2
		Works on: Windows Server 2008 R2 and above
	.EXAMPLE
		.\autopart_win.ps1 -DriveLetter T -DriveLabel DISK01
	.EXAMPLE
		.\autopart_win.ps1
#>

param (
    [Parameter(Mandatory=$false, Position=0)] [string]$RequestedDriveLetter, 
    [Parameter(Mandatory=$false, Position=1)] [string]$RequestedDriveLabelPrefix = "DISK"  
)

#Constant array with forbidden drive letters
$ForbiddenDriveLetters = @("A","B","D","E","F","G","X","Z")

#function that returns partition letter
Function find_driver_letter ([string]$RequestedDriveLetter, [array]$ForbiddenDriveLetters)
{
	#if letter not specified set it to C. Whatever
	if (!$RequestedDriveLetter) { $RequestedDriveLetter = "C"}
	#if (!$ForbiddenDriveLetters) { $ForbiddenDriveLetters = @("A","B","D","E","F","G","X","Z") }
	#Fill up AllowedDriveLetters  array
	$AllowedDriveLetters = [char[]](0..255) -clike "[A-Z]"
	
	#Get disk drive letters in use on the system
	$UsedDriveLetters = Get-WmiObject -Class Win32_Volume | select DriveLetter | ?{$_.DriveLetter} | %{$_.DriveLetter.replace(":","")}
	#$UsedDriveLetters

	#Exlude forbidden drive letters and used drive letters
	$AllowedDriveLetters = $AllowedDriveLetters | ? {$ForbiddenDriveLetters -NotContains $_}
	$AllowedDriveLetters = $AllowedDriveLetters | ? {$UsedDriveLetters -NotContains $_}

	#if requested letter is taken or prohibited, then assign first available
	if (($ForbiddenDriveLetters -contains $RequestedDriveLetter) -or ($UsedDriveLetters -contains $RequestedDriveLetter)) {
		if($AllowedDriveLetters.Length -gt 0) {
			$RequestedDriveLetter = $AllowedDriveLetters[0]
		} else {
			$RequestedDriveLetter = $null;			
		}
	}

	return $RequestedDriveLetter
}

#function that returns first available unpartitioned disk 
Function scan_for_new_disks
{
	return Get-WmiObject -Query "select * from  WIN32_DiskDrive where partitions=0" | %{$_.index}
}
	
$newDisksIndexes = scan_for_new_disks
if(($newDisksIndexes | measure).count -lt 1) {"Unexpected. No new disk found."; }

ForEach($NewDiskNumber in $newDisksIndexes){
	$NewDiskLabel = "$($RequestedDriveLabelPrefix)$($NewDiskNumber)"
	$newDiskLetter = find_driver_letter -RequestedDriveLetter $RequestedDriveLetter -ForbiddenDriveLetters $ForbiddenDriveLetters
	
	#check if all letters are taken
	if(!$newDiskLetter) {Write-Error "All letters are taken. No letters available. Mapping Failed." -Category ResourceUnavailable; exit;}	
	
	#bulding diskpart script output
	$diskpart_command = "
	SELECT DISK $NewDiskNumber
	ATTRIBUTES DISK CLEAR READONLY
	ONLINE DISK
	CONVERT MBR
	CREATE PARTITION PRIMARY
	ASSIGN LETTER=$newDiskLetter
	ACTIVE
	FORMAT FS=NTFS QUICK LABEL=$NEWDISKLABEL
	"
	$diskpart_command
	$diskpart_command | diskpart
}
""
"The script completed successfully"
	