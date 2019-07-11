SYNOPSIS

Quick and dirty script to automaticaly partition and format new disks presented to a system

DESCRIPTION

This PowerShell script is to support automated discovery, mounting and formatting of a new disk devices presented to a Windows OS. Arguments allow to define disk letter and drive label preffix (optional). If no arguments defined then scripts searches for new devices, partitions them and creates NTFS file system, drive letter and labels assigned automatically.

Tested on: Windows Server 2008 R2 and Windows Server 2012 R2

EXAMPLE1

.\autopart_win.ps1 -RequestedDriveLetter T -RequestedDriveLabelPrefix DISK01

EXAMPLE2

.\autopart_win.ps1
