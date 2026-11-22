do shell script "pkill -f \"rickroll.app/Contents/MacOS/applet\" 2>/dev/null || true; killall player 2>/dev/null || true" 
display dialog "Watcher stopped." buttons {"OK"} giving up after 2