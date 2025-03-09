@echo off
:: Set the folder path for saving screenshots
set folderPath=%USERPROFILE%\Desktop\Check_Code

:: Check if ADB is available
adb version >nul 2>&1
if %errorlevel% neq 0 (
    echo ADB not found! Please install ADB first.
    pause
    exit /b
)

:: Check and create the folder if it doesn't exist
if not exist "%folderPath%" (
    mkdir "%folderPath%"
    echo Created new folder: %folderPath%
)

:: Loop to capture screenshots from ports 5501 - 5505
for /l %%p in (5501,1,5560) do (
    echo Capturing screenshot from BlueStacks port %%p ...

    :: Connect to ADB
    adb connect 127.0.0.1:%%p >nul 2>&1
    if %errorlevel% neq 0 (
        echo Unable to connect ADB on port %%p! Stopping process.
        pause
        exit /b
    )

    :: Capture screenshot and save it to BlueStacks SD Card
    adb shell screencap -p /sdcard/screenshot_%%p.png

    :: Pull the file to Check_Code folder
    adb pull /sdcard/screenshot_%%p.png "%folderPath%\screenshot_%%p.png" >nul 2>&1

    :: Check if the file was successfully pulled
    if not exist "%folderPath%\screenshot_%%p.png" (
        echo Failed to retrieve screenshot from port %%p! Stopping process.
        adb disconnect 127.0.0.1:%%p
        pause
        exit /b
    )

    :: Disconnect ADB
    adb disconnect 127.0.0.1:%%p

    echo Screenshot captured for port %%p (Saved in %folderPath%)
)

echo Screenshot capturing completed! All files are in: %folderPath%

:: Open the Check_Code folder
explorer "%folderPath%"

:: Open the screenshot_5501.png file if it exists
if exist "%folderPath%\screenshot_5501.png" start "" "%folderPath%\screenshot_5501.png"

:: Prompt the user to press Enter to confirm deletion
echo.
echo Press Enter to delete all screenshots, or close this window to cancel.
pause >nul

:: Delete all screenshots in the folder
del /q "%folderPath%\screenshot_*.png"

echo All screenshots have been deleted!

pause
