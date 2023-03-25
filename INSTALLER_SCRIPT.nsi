# This installs two files, app.exe and logo.ico, creates a start menu shortcut, builds an uninstaller, and
# adds uninstall information to the registry for Add/Remove Programs
 
# To get started, put this script into a folder with the two files (app.exe, logo.ico, and license.rtf -
# You'll have to create these yourself) and run makensis on it
 
# If you change the names "app.exe", "logo.ico", or "license.rtf" you should do a search and replace - they
# show up in a few places.
# All the other settings can be tweaked by editing the !defines at the top of this script
!define APPNAME "Arena-Tournament.net Launcher"
!define COMPANYNAME "Arena-Tournament.net"
!define DESCRIPTION "Arena-Tournament.net Launcher"
# These three must be integers
!define VERSIONMAJOR 1
!define VERSIONMINOR 1
!define VERSIONBUILD 1
# These will be displayed by the "Click here for support information" link in "Add/Remove Programs"
# It is possible to use "mailto:" links in here to open the email client
!define HELPURL "https://Arena-Tournament.net" # "Support Information" link
!define UPDATEURL "https://Arena-Tournament.net" # "Product Updates" link
!define ABOUTURL "https://Arena-Tournament.net" # "Publisher" link
# This is the size (in kB) of all the files copied into "Program Files"
!define INSTALLSIZE 7233

RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)
 
InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
 
# This will be in the installer/uninstaller's title bar
Name "${APPNAME}"
Icon "app_icon.ico"
outFile "arena-tournament-installer.exe"
 
!include LogicLib.nsh
!include "MUI2.nsh"
!define MUI_ICON "app_icon.ico"
!define MUI_UNICON "app_icon.ico"

# Just three pages - license agreement, install location, and installation
page directory
Page instfiles
!define MUI_FINISHPAGE_RUN "$INSTDIR\arena_tournament_launcher.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Run Arena-Tournament.net Launcher"
!define MUI_FINISHPAGE_RUN_CHECKED
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE English
 
!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
${If} $0 != "admin" ;Require admin rights on NT4+
        messageBox mb_iconstop "Administrator rights required!"
        setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
        quit
${EndIf}
!macroend
 
function .onInit
	setShellVarContext all
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "install"
	# Files for the install directory - to build the installer, these should be in the same directory as the install script (this file)
	setOutPath $INSTDIR
	# Files added here should be removed by the uninstaller (see section "uninstall")
	file "arena_tournament_launcher.exe"
	file "app_icon.ico"
	file "flutter_windows.dll"
	file "msvcp140.dll"
	file "vcruntime140.dll"
	file "vcruntime140_1.dll"

	setOutPath $INSTDIR\data
    file "data\app.so"
    file "data\icudtl.dat"

	setOutPath $INSTDIR\data\flutter_assets
    file "data\flutter_assets\FontManifest.json"
    file "data\flutter_assets\NOTICES.Z"
    file "data\flutter_assets\AssetManifest.json"

	setOutPath $INSTDIR\data\flutter_assets\assets\exe
    file "data\flutter_assets\assets\exe\aria2cj.exe"

	setOutPath $INSTDIR\data\flutter_assets\fonts
    file "data\flutter_assets\fonts\MaterialIcons-Regular.otf"

	setOutPath $INSTDIR\data\flutter_assets\packages\cupertino_icons\assets
    file "data\flutter_assets\packages\cupertino_icons\assets\CupertinoIcons.ttf"
	# Add any other files for the install directory (license files, app data, etc) here
 
	# Uninstaller - See function un.onInit and section "uninstall" for configuration
	writeUninstaller "$INSTDIR\uninstall.exe"
 
	# Start Menu
	createDirectory "$SMPROGRAMS\${COMPANYNAME}"
	createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\arena_tournament_launcher.exe" "" "$INSTDIR\app_icon.ico"
 
	# Registry information for add/remove programs
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${APPNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$\"$INSTDIR\logo.ico$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "$\"${COMPANYNAME}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "HelpLink" "$\"${HELPURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLUpdateInfo" "$\"${UPDATEURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLInfoAbout" "$\"${ABOUTURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "$\"${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}$\""
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMinor" ${VERSIONMINOR}
	# There is no option for modifying or repairing the install
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1
	# Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
sectionEnd
 
# Uninstaller
 
function un.onInit
	SetShellVarContext all
 
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanantly remove ${APPNAME}?" IDOK next
		Abort
	next:
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "uninstall"
 
	# Remove Start Menu launcher
	delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
	# Try to remove the Start Menu folder - this will only happen if it is empty
	rmDir "$SMPROGRAMS\${COMPANYNAME}"
 
	# Remove files
 	delete $INSTDIR\arena_tournament_launcher.exe
 	delete $INSTDIR\app_icon.ico
	delete $INSTDIR\flutter_windows.dll
	delete $INSTDIR\msvcp140.dll
	delete $INSTDIR\vcruntime140.dll
	delete $INSTDIR\vcruntime140_1.dll
    delete $INSTDIR\data\app.so
    delete $INSTDIR\data\icudtl.dat
    delete $INSTDIR\data\flutter_assets\FontManifest.json
    delete $INSTDIR\data\flutter_assets\NOTICES.Z
    delete $INSTDIR\data\flutter_assets\AssetManifest.json
    delete $INSTDIR\data\flutter_assets\assets\exe\aria2cj.exe
    delete $INSTDIR\data\flutter_assets\fonts\MaterialIcons-Regular.otf
    delete $INSTDIR\data\flutter_assets\packages\cupertino_icons\assets\CupertinoIcons.ttf
	
	rmDir $INSTDIR\data\flutter_assets\assets\exe
	rmDir $INSTDIR\data\flutter_assets\assets
	rmDir $INSTDIR\data\flutter_assets\packages\cupertino_icons\assets
	rmDir $INSTDIR\data\flutter_assets\packages\cupertino_icons
	rmDir $INSTDIR\data\flutter_assets\packages
	rmDir $INSTDIR\data\flutter_assets\fonts
	rmDir $INSTDIR\data\flutter_assets
    rmDir $INSTDIR\data

	# Always delete uninstaller as the last action
	delete $INSTDIR\uninstall.exe
 
	# Try to remove the install directory - this will only happen if it is empty
	rmDir $INSTDIR
 
	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
sectionEnd