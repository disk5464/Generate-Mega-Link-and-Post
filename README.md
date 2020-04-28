#### Description ####
This script will get a folder, get the subfolders and see if they are on your mega drive. If the sub folder is it will generate a base 64 encoded link along with a post. It will use a file called New Text Document.txt located within the sub folder to put the description into the folder. 

This was mainly designed to help post a bunch of pluralsight courses at once. In order for this to work you need to have already uploaded the course to mega and have that new text document with the course description ready to go

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
