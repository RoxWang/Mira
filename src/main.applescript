-- Mira：接收访达「打开方式」传来的文件，交给浏览器播
on open theFiles
	repeat with f in theFiles
		set p to POSIX path of f
		set launcher to POSIX path of (path to me) & "Contents/MacOS/reel-launch"
		-- 同步调用：要拿回结果才知道目录有没有被系统挡住
		set r to do shell script quoted form of launcher & " " & quoted form of p
		if r is "BLOCKED" then my askAccess()
	end repeat
end open

on run
	set launcher to POSIX path of (path to me) & "Contents/MacOS/reel-launch"
	do shell script "nohup " & quoted form of launcher & " >/dev/null 2>&1 &"
end run

-- 设置里「更改默认浏览器」走这里：
-- 网页（哪怕是本地 app 的页面）写不了磁盘，所以页面点一下 → mira:// 协议 → 本处理器写配置文件。
--   mira://setbrowser?id=com.microsoft.edgemac  → 固定用 Edge
--   mira://setbrowser                         → 恢复「跟随系统默认」
-- reel-launch 每次开视频都会读 ~/Library/Application Support/Mira/browser，所以这里写完即生效（下次开视频）。
on open location theURL
	set bid to do shell script "printf '%s' " & quoted form of theURL & " | sed -n 's/.*id=\\([^&]*\\).*/\\1/p' | tr -d '[:space:]'"
	set prefsDir to (system attribute "HOME") & "/Library/Application Support/Mira"
	set msg to ""
	if bid is "" then
		do shell script "rm -f " & quoted form of (prefsDir & "/browser")
		set msg to "已恢复：跟随系统默认浏览器"
	else
		do shell script "mkdir -p " & quoted form of prefsDir & " && printf '%s\\n' " & quoted form of bid & " > " & quoted form of (prefsDir & "/browser")
		set msg to "已设为用 " & my browserName(bid) & " 打开视频（下次打开视频生效）"
	end if
	display dialog msg buttons {"好"} default button 1 with icon note giving up after 6
end open location

on browserName(bid)
	if bid is "com.google.Chrome" then return "Google Chrome"
	if bid is "com.microsoft.edgemac" then return "Microsoft Edge"
	if bid is "com.brave.Browser" then return "Brave"
	if bid is "com.vivaldi.Vivaldi" then return "Vivaldi"
	if bid is "company.thebrowser.Browser" then return "Arc"
	if bid is "com.operasoftware.opera" then return "Opera"
	if bid is "org.chromium.Chromium" then return "Chromium"
	if bid is "com.apple.Safari" then return "Safari"
	if bid is "org.mozilla.firefox" then return "Firefox"
	return bid
end browserName

-- macOS 不让它列 Downloads / Documents / Desktop 里的东西。
-- 这是苹果的规矩：有 bundle id 的 app 默认没有这些目录的读取权。
-- 只能请用户去系统设置里给 Mira 开一次，之后永久生效。
on askAccess()
	set dlg to display dialog "Mira can't list this folder — macOS is blocking it." & return & return & "Give Mira access once in Privacy & Security, and the playlist comes back for good." buttons {"Continue", "Open Settings"} default button 2 with icon caution giving up after 60
	if button returned of dlg is "Open Settings" then
		open location "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
	end if
end askAccess
