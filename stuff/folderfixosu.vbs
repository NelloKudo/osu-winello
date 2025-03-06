winPath = WScript.Arguments(0)

If Left(winPath, 1) = """" And Right(winPath, 1) = """" Then
    winPath = Mid(winPath, 2, Len(winPath) - 2)
End If

openPath = Replace(winPath, "\", "/")

cmd = "winebrowser.exe ""file:///" & openPath

Set WshShell = CreateObject("WScript.Shell")
WshShell.Run cmd, 0, False
Set WshShell = Nothing
