set appDir to (POSIX path of (path to application support folder from user domain)) & "RickrollWatcher/"
set cfg to appDir & "config.json"
set defCfg to (POSIX path of (path to home folder)) & "Applications/rickroll.app/Contents/Resources/config.json"
do shell script "mkdir -p " & quoted form of appDir & " && [ -f " & quoted form of cfg & " ] || cp " & quoted form of defCfg & " " & quoted form of cfg
do shell script "open -e " & quoted form of cfg
display dialog "Edit config.json and save (Cmd+S), then click Reload to apply." buttons {"Close", "Reload"} default button "Reload"
if button returned of result is "Reload" then
  do shell script "pkill -f \"rickroll.app/Contents/MacOS/applet\" 2>/dev/null || true; sleep 0.3; open \"$HOME/Applications/rickroll.app\""
end if