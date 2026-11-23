property targetFolder : ""
property videoName : ""
property checkInterval : 0.5
property isQuitting : false

on writeLog(msg)
	try
		do shell script "printf '%s %s\\n' \"$(date '+%H:%M:%S')\" " & quoted form of msg & " >> /tmp/rickroll.log"
	end try
end writeLog

on openConfigure()
	try
		set myAppPath to POSIX path of (path to me)
		set parentDir to do shell script "dirname " & quoted form of myAppPath
		set localCfgApp to parentDir & "/Configure.app"
		set userCfgApp to (POSIX path of (path to home folder)) & "Applications/Configure.app"
		do shell script "if [ -d " & quoted form of localCfgApp & " ]; then open " & quoted form of localCfgApp & "; elif [ -d " & quoted form of userCfgApp & " ]; then open " & quoted form of userCfgApp & "; fi"
	end try
end openConfigure

on fatalExit(contextMsg, errMsg)
	if isQuitting then return
	set isQuitting to true
	my writeLog(contextMsg & ": " & errMsg)
	set shouldOpenConfig to true
	try
		activate
		set res to display dialog contextMsg & ":" & return & errMsg buttons {"Quit", "Open Configure"} default button "Open Configure" with icon stop giving up after 5
		if (gave up of res is false) and (button returned of res is "Quit") then
			set shouldOpenConfig to false
		end if
	end try
	if shouldOpenConfig then my openConfigure()
	quit
end fatalExit

on run
	my writeLog("--- App Started ---")
	try
		my loadConfig()
		set testAlias to (POSIX file targetFolder) as alias
		my writeLog("Config Loaded: " & targetFolder)
	on error errMsg
		my fatalExit("Startup Error", errMsg)
	end try
end run

on loadConfig()
	set defaultConfig to POSIX path of (path to resource "config.json")
	set appSupportDir to (POSIX path of (path to application support folder from user domain)) & "RickrollWatcher/"
	set configPath to appSupportDir & "config.json"

	do shell script "mkdir -p " & quoted form of appSupportDir & " && [ -f " & quoted form of configPath & " ] || cp " & quoted form of defaultConfig & " " & quoted form of configPath

	set rawTarget to do shell script "plutil -extract targetFolder raw -o - " & quoted form of configPath
	if rawTarget starts with "~/" then
		set targetFolder to (POSIX path of (path to home folder)) & (text 3 thru -1 of rawTarget)
	else
		set targetFolder to rawTarget
	end if
	set videoName to do shell script "plutil -extract videoName raw -o - " & quoted form of configPath
	set checkInterval to (do shell script "plutil -extract interval raw -o - " & quoted form of configPath) as number
end loadConfig

on idle
	if isQuitting then return 0

	-- 1. Check config & target folder existence (Fatal if missing)
	try
		if targetFolder is "" then my loadConfig()
		set targetHFS to ((POSIX file targetFolder) as alias) as text
	on error errMsg
		my fatalExit("Target Folder Error", errMsg)
		return 0
	end try

	-- 2. Query Finder windows (Ignore transient Finder busy errors like Emptying Trash)
	set matchedWindow to missing value
	try
		tell application "Finder"
			set winList to every Finder window
			repeat with aWindow in winList
				try
					set winHFS to (target of aWindow as alias) as text
					if winHFS is targetHFS then
						set matchedWindow to aWindow
						exit repeat
					end if
				end try
			end repeat
		end tell
	end try

	-- 3. Close matched window and launch player (Fatal if player/video fails)
	if matchedWindow is not missing value then
		try
			my writeLog("Match Found! Launching player...")
			tell application "Finder" to close matchedWindow
			my playRickroll()
		on error errMsg
			my fatalExit("Playback Error", errMsg)
			return 0
		end try
	end if

	return checkInterval
end idle

on playRickroll()
	set videoPath to POSIX path of (path to resource videoName)
	set playerPath to POSIX path of (path to resource "player")
	do shell script "test -f " & quoted form of videoPath & " && test -x " & quoted form of playerPath
	my writeLog("Playing: " & videoPath)
	do shell script "killall player 2>/dev/null || true; " & quoted form of playerPath & " " & quoted form of videoPath & " >/dev/null 2>&1 &"
end playRickroll

on quit
	set isQuitting to true
	my writeLog("--- App Terminated ---")
	continue quit
end quit
