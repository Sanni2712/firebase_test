Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell -ExecutionPolicy Bypass -File ""C:\sounds\playloop.ps1""", 0, False
