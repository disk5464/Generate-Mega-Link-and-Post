<#
This script will take a folder path and generate a link for all the folders within it and then put thoes links into a persistent file. It will also generate a text file that you can copy paste into a new post. 
Author: Disk546 (with reused code from rouben)
Last modified 4/22/20

In order for this to work you need to first install megaCMD. You can get it here https://mega.nz/cmd
This has only been tested on Windows thus far. It should work on Linux but I haven't tried it.
Alot of it is repurposed code from my UploadToMega script. You can get it here https://github.com/disk5464/UploadToMega
If you have any questions, find any bugs, or want to help optimize this feel free to DM me. Enjoy!

#### Change Log ####
V1  Created the script

#### Known Issues ####
None at the moment.

#### Dependencies ####
 1. PowerShell
 2. MEGAcmd: mega-whoami (.bat), mega-login (.bat), mega-df (.bat), mega-transfers (.bat),
    mega-export (.bat), mega-put.
#>
#################################################################
#################################################################
# Detect the OS and try to set the environment variables for MEGAcmd.
# This is a little workaround for PowerShell < 6, which still ships with Windows...
# Linux and macOS have PowerShell 6+ by default when installed from Microsoft's site
if ( ($PSVersionTable.PSVersion.Major -lt 6) -And !([string]::IsNullOrEmpty($env:OS)) -And ([string]::IsNullOrEmpty($IsWindows)) ) {
    $IsWindows = $True
}
if ($IsWindows) {
    $MEGApath = "$env:LOCALAPPDATA\MEGAcmd"
    $OS = "Windows"
    $PathVarSeparator = ";"
    $PathSeparator = "\"
}
elseif ($IsMacOS) {
    $MEGApath = "/Applications/MEGAcmd.app/Contents/MacOS"
    $OS = "macOS"
    $PathVarSeparator = ":"
    $PathSeparator = "/"
}
elseif ($isLinux) {
    $MEGApath = "/usr/bin"
    $OS = "Linux"
    $PathVarSeparator = ":"
    $PathSeparator = "/"
}
else {
    Write-Error "Unknown OS! Bailing..."
    Exit
}

#################################################################
# Check if MEGAcmd is already installed and in the PATH
# This gives access to the MEGAcmd executables and wrapper scripts.
$deps = "mega-whoami","mega-login","mega-df","mega-transfers","mega-export","mega-put"
foreach ($dep in $deps) {
    Write-Host -NoNewline "Checking for $dep..."
    if (Get-Command $dep -ErrorAction SilentlyContinue) { 
        Write-Host "found!"
    }
    else {
        Write-Host "not found! I'm going to try and fix this by setting PATH..."
        Write-Host "$OS detected! Assuming MEGAcmd lives under $MEGApath."
        Write-Host "Checking for MEGAcmd and setting paths. If this hangs, exit and retry." -ForegroundColor Yellow
        if (Test-Path $MEGApath) {
            $env:PATH += "$PathVarSeparator$MEGApath"
        }
        else {
            Write-Error "MEGAcmd doesn't seem to exist under $MEGApath! Please install" +
            "MEGAcmd and/or update this script accordingly."
            Exit
        }
    }
}

#Test to see if MEGAcmd is running and if not start it
$ProcessActive = Get-Process MEGAcmdServer -ErrorAction SilentlyContinue
if($null -eq $ProcessActive)
{
    Write-host "MegaCMD is not running. Starting MegaCMD" -ForegroundColor Magenta
    #MEGAcmdShell
}
else
{
    Write-host "MegaCMD already running" -ForegroundColor  green
}
#################################################################
#This will test to see if a user is logged in and if not prompt them to log in
$testLogin = mega-whoami
if ($testLogin -like '*Not logged in.*')
{
    Write-Host "User not logged in, prompting for credentials" -ForegroundColor Yellow
    $creds = Get-Credential -Message "Please enter your Mega username and password" 

    mega-login $creds.UserName $creds.GetNetworkCredential().Password 
}
#################################################################
#Display who the current user is.
$UserEmailPre = mega-whoami
Write-Host $UserEmailPre
#################################################################
#This will create the template for the menu
Write-Host "========================================================="-ForegroundColor Yellow
Write-Host "================ Please Make a Selection ================" -ForegroundColor Yellow
    
Write-Host "1: Press '1' for a tv/show."-ForegroundColor Yellow
Write-Host "2: Press '2' for a Pluralsight tutorial."-ForegroundColor Yellow
Write-Host "3: Press '3' for a Curiosity Stream upload."-ForegroundColor Yellow
Write-Host "========================================================="-ForegroundColor Yellow
$input = Read-Host " "
#################################################################
#This step asks for the file/folder path of the thing(s) you are trying to generate the post and link for.
$FilePath = Read-Host "Enter the entire folder path of the courses" 
#################################################################
#Setup the variable for the post
$sEncodedString = ""
$course = ""
$totalsize = ""
$SizeUnit =  ""
$sizeBracket = ""
#################################################################
#Get the list of items in the folder
$courses = Get-ChildItem -Path $FilePath -Name
#################################################################
#For each item in the list
foreach($course in $courses)
{
    #First need to get the file name. To do this we need to export the link(-a) and the -f flag to auto-accept the copyright notice
    $ExportedLink = mega-export -a -f  $course
    $ShortLink = $ExportedLink.Split(":",2)[1].Replace(" ","")

    #Next, we need to encode it.
    $sEncodedString=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ShortLink))

    #Display the total size in GB of the files being uploaded
    $SizeToBeFormated = (Get-ChildItem $FilePath\$course -recurse | Measure-Object -property length -sum).sum / 1GB
    $TotalSize  = [math]::Round($SizeToBeFormated,2)
    $SizeUnit = "GB"
    $sizeBracket = "[$totalsize $SizeUnit]"

    #If the size is less than one GB switch the units
    if($TotalSize -lt 1)
    {
        #Convert the size from GB to MB and round 
        $SizeinGB = (Get-ChildItem $FilePath\$course -recurse | Measure-Object -property length -sum).sum / 1MB
        $TotalSize  = [math]::Round($SizeinGB,0)
        $SizeUnit = "MB"
        $sizeBracket = "[$totalsize $SizeUnit]"
    }
#create the post and fill in the info with the variables
if($input -eq 1)
{
$post ="

[mediainfo][/mediainfo]


As always decode with [url]https://www.base64decode.org[/url] and enjoy!
[hide]$sEncodedString [/hide]
[Mega] $course $sizeBracket"
}

if($input -eq 2)
{
$post ="[quote][/quote]
Course Files Included!

[mediainfo][/mediainfo]


As always decode with [url]https://www.base64decode.org[/url] and enjoy!
[hide]$sEncodedString [/hide]
[Mega]Pluralsight: $course $sizeBracket"
}

if($input -eq 3)
{
$post ="[quote][/quote]


[mediainfo][/mediainfo]


As always decode with [url]https://www.base64decode.org[/url] and enjoy!
[hide]$sEncodedString [/hide]
[Mega]$course $sizeBracket"
}

    #Now take all of the parts and put it into a new file
    $PostOutput = "$FilePath\$course.txt"
    New-Item -Path $PostOutput -Value $post -ErrorAction SilentlyContinue

    #Open the new file
    if ($IsWindows) 
    {
        Start-Process $FilePath\$course.txt
    }
    else 
    {
        open $FilePath\$course.txt
    }

    #This assembles a HTML link and opens the browser to it so that you can get the description and the excerise files.
    $URLNoSpaces = $course.replace(" ","-")
    if ($URLNoSpaces -contains "--")
    {
        $URLNoDoubleDash = $URLNoSpaces.Replace("--","-")    
    }

    #This launches Opera to (hopefully) the course page
    $SiteURL = "www.pluralsight.com/" + $URLNoDoubleDash
    start-process -FilePath 'C:\Program Files\Opera\launcher.exe' -ArgumentList $SiteURL
}

Read-Host -Prompt "Press any key to close"







