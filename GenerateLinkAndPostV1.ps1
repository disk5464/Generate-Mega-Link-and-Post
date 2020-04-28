<#
This script will take a folder path, generates links for each folder, and then produces a text file with all the infomation needed for a post.
Author: Disk546 (with reused code from rouben)
Last modified 4/28/20

#### How To Use ####
In order for this to work you need to first install megaCMD. You can get it here https://mega.nz/cmd
Do note that the folder must have already been uploaded to mega and in the root directory. For that see https://github.com/disk5464/UploadToMega
First Download, decrypt, and downlnoad the course files. Next inside each course create a new text file (don't change the name) and fill it with the course description.
Next run the script and follow the directions. This will produce a file with a post ready to go. 
This has only been tested on Windows thus far. It should work on Linux but I haven't tried it.
If you have any questions, find any bugs, or want to help optimize this feel free to DM me. Enjoy!

#### Change Log ####
V1  Created the script

#### Known Issues ####
A lot of the time the pluralsight url takes you to a error 404 page. This is because pluralsight's naming scheme isn't consistant.

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
#This step asks for the file/folder path of the thing(s) you are trying to generate the post and link for.
$FilePath = Read-Host "Enter the entire folder path of the courses" 
#################################################################
#Setup the variable for the post
$sEncodedString = ""
$course = ""
$totalsize = ""
$SizeUnit =  ""
$sizeBracket = ""
$DescriptionFile = ""
#################################################################
#Get the list of items in the folder
$courses = Get-ChildItem -Path $FilePath -Name
#################################################################
#For each item in the list
foreach($course in $courses)
{
    #This will get the description from a file called New Text Document from within the course
    $DescriptionFile = Get-content -Path "$FilePath\$course\New Text Document.txt" -ErrorAction SilentlyContinue
    
    #First we need to get the link. To do this we need to export the link(-a) and the -f flag to auto-accept the copyright notice
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
#Create the post and fill in the info with the variables. Don't indent this otherwise the entire post will be indented
$post ="[quote]$DescriptionFile[/quote]
Course Files Included!

[mediainfo][/mediainfo]


As always decode with [url]https://www.base64decode.org[/url] and enjoy!
[hide]$sEncodedString [/hide]
[Mega]Pluralsight: $course $sizeBracket"


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

    <#
    #This assembles a HTML link and opens the browser to it so that you can get the description and the excerise files.
    The way that the script is to be used has shifted so this seciton isn't necessary but I don't wanna get rid of it quite yet.

    $URLNoSpaces = $course.replace(" ","-")
    if ($URLNoSpaces -contains "--")
    {
        #Things to help fix the url can be added in this space. The final output should be in the $finalURL variable.
        $URLNoDoubleDash = $URLNoSpaces.Replace("--","-") 
        $FinalURL = $URLNoDoubleDash
    }
    else
    {
        $FinalURL = $URLNoSpaces    
    }

    #This launches Opera to (hopefully) the course page. Pluralsight's url don't usually follow the course name so sometimes you'll go to a error 404 
    #but most times they have a suggestion which is oftentimes the correct page.
    #It's not perferct but it's better than having to do it all by hand.
    $SiteURL = "https://pluralsight.com/library/courses/" + $FinalURL + "/description"
    start-process -FilePath 'C:\Program Files\Opera\launcher.exe' -ArgumentList $SiteURL
    #>
}

Read-Host -Prompt "Press any key to close"


















