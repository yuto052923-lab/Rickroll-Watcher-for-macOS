property targetFolder : ""
property videoName : ""
property checkInterval : 0.5
property isQuitting : false

on writeLog(msg)
	try
		do shell script "echo \"$(date '+%H:%M:%S') " & msg & "\" >> /tmp/rickroll.log"
	end try
end writeLog

on fatalExit(contextMsg, errMsg)
	if isQuitting then return
	set isQuitting to true
	my writeLog(contextMsg & ": " & errMsg)
	try
		activate
		display dialog contextMsg & ":" & return & errMsg buttons {"OK"} default button "OK" with icon stop giving up after 5
	end try
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

	-- ??????????config.json??????????????
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
	try
		if targetFolder is "" then my loadConfig()
		set targetHFS to ((POSIX file targetFolder) as alias) as text
		tell application "Finder"
			set winList to every Finder window
			repeat with aWindow in winList
				set hasTarget to true
				try
					set winHFS to (target of aWindow as alias) as text
				on error
					set hasTarget to false
				end try

				if hasTarget and (winHFS is targetHFS) then
					my writeLog("Match Found! Launching player...")
					close aWindow
					my playRickroll()
				end if
			end repeat
		end tell
	on error errMsg
		my fatalExit("Runtime Error", errMsg)
		return 0
	end try
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
