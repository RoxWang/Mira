-- Mira：接收访达「打开方式」传来的文件，交给 Chrome 播
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

-- macOS 不让它列 Downloads / Documents / Desktop 里的东西。
-- 这是苹果的规矩：有 bundle id 的 app 默认没有这些目录的读取权。
-- 只能请用户去系统设置里给 Mira 开一次，之后永久生效。
on askAccess()
	set dlg to display dialog "Mira can't list this folder — macOS is blocking it." & return & return & "Give Mira access once in Privacy & Security, and the playlist comes back for good." buttons {"Continue", "Open Settings"} default button 2 with icon caution giving up after 60
	if button returned of dlg is "Open Settings" then
		open location "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
	end if
end askAccess
