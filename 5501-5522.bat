@echo off
:: Set the folder path for saving screenshots
set folderPath=%USERPROFILE%\Desktop\Check_Code

:: ตรวจสอบว่าพบ ADB ในระบบหรือไม่
where adb >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ADB not found in system PATH! กรุณาตรวจสอบการติดตั้ง ADB.
    pause
    exit /b
)

:: แสดงตำแหน่งของ adb.exe (ใช้เพื่อ Debug)
for /f "delims=" %%a in ('where adb') do set adbPath=%%a
echo [INFO] ADB Path: %adbPath%

:: Restart ADB to ensure fresh connection
adb start-server
timeout /t 2 /nobreak >nul

:: ตรวจสอบ ADB version อีกครั้ง
adb version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ADB ยังไม่พร้อมใช้งานหลังจากรีสตาร์ท! กำลังลองใหม่...
    timeout /t 2 /nobreak >nul
    adb start-server
)

:: Check and create the folder if it doesn't exist
if not exist "%folderPath%" (
    mkdir "%folderPath%"
    echo [INFO] Created new folder: %folderPath%
)

:: Loop to capture screenshots from ports 5531 - 5560
for /l %%p in (5501,1,5522) do (
    echo [INFO] Capturing screenshot from BlueStacks port %%p ...

    :: Try to connect ADB
    adb connect 127.0.0.1:%%p >nul 2>&1
    if %errorlevel% neq 0 (
        echo [WARNING] Unable to connect ADB on port %%p! Skipping to next port.
        adb disconnect 127.0.0.1:%%p >nul 2>&1
        timeout /t 1 /nobreak >nul
    ) else (
        echo [INFO] Connected to ADB on port %%p.

        :: ตรวจสอบว่า ADB มองเห็นอุปกรณ์นี้หรือไม่
        adb -s 127.0.0.1:%%p shell echo "device found" >nul 2>&1
        if %errorlevel% neq 0 (
            echo [WARNING] Device not found on port %%p! Skipping to next port.
            adb disconnect 127.0.0.1:%%p >nul 2>&1
            timeout /t 1 /nobreak >nul
            goto NEXT_PORT
        )

        :: Capture screenshot and save to BlueStacks SD Card
        adb -s 127.0.0.1:%%p shell screencap -p /sdcard/screenshot_%%p.png

        :: Pull the file to Check_Code folder
        adb -s 127.0.0.1:%%p pull /sdcard/screenshot_%%p.png "%folderPath%\screenshot_%%p.png" >nul 2>&1

        :: Verify file existence
        if not exist "%folderPath%\screenshot_%%p.png" (
            echo [WARNING] Failed to retrieve screenshot from port %%p! Skipping to next port.
        ) else (
            echo [SUCCESS] Screenshot captured for port %%p (Saved in %folderPath%)
        )

        :: Disconnect ADB
        adb disconnect 127.0.0.1:%%p >nul 2>&1
        timeout /t 1 /nobreak >nul
    )
    :NEXT_PORT
)

echo [INFO] Screenshot capturing completed! All files are in: %folderPath%

:: Open the Check_Code folder
explorer "%folderPath%"

:: Open the screenshot_5531.png file if it exists
if exist "%folderPath%\screenshot_5501.png" start "" "%folderPath%\screenshot_5501.png"

:: Schedule deletion of screenshots after CMD closes
(
    echo @echo off
    echo timeout /t 3 /nobreak
    echo del /q "%folderPath%\screenshot_*.png"
    echo rmdir /q "%folderPath%" 2^>nul
) > "%temp%\delete_screenshots.bat"
start /b "%temp%\delete_screenshots.bat"

echo [INFO] Program execution completed. Closing in 3 seconds...
timeout /t 3 /nobreak >nul
exit
