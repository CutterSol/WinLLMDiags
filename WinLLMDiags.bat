@echo off
setlocal

:: Version Information
set "scriptVersion=1.2.10"

:: Set error handling
set "error_log=log.txt"
echo Starting LLM Diagnostics Tool - Version %scriptVersion% at %date% %time% > %error_log%
echo Diagnostic files will be saved in: C:\_LLMDiag\LLMDiagX >> %error_log%
echo ------------------------------------------------------------------------------ >> %error_log%

:: Create diagnostic directory
call :CreateDiagDir

echo.
echo === LLM Diagnostics Tool - Version %scriptVersion% ===
echo.

:mainMenu
echo.
echo === Main Menu ===
echo 1. GPU Diagnostics
echo 2. System Information
echo 3. Python and PyTorch Diagnostics
echo 4. HIP Installation Diagnostics
echo 5. Generate HTML Report from Existing Data
echo 6. Comprehensive Diagnostics (all steps and generate HTML)
echo 7. Open HTML Report
echo 8. Exit
echo.
set /p "choice=Enter your choice: "

echo.
if "%choice%"=="1" call :CheckGPU & pause & goto mainMenu
if "%choice%"=="2" call :CollectSystemInfo & pause & goto mainMenu
if "%choice%"=="3" call :CheckPython & pause & goto mainMenu
if "%choice%"=="4" call :CheckHIP & pause & goto mainMenu
if "%choice%"=="5" call :GenerateHTML & pause & goto mainMenu
if "%choice%"=="6" call :RunComprehensive & pause & goto mainMenu
if "%choice%"=="7" call :OpenHTML & pause & goto mainMenu
if "%choice%"=="8" goto :exit

echo Invalid choice. Please try again.
pause
goto mainMenu

:RunComprehensive
echo === Running Comprehensive Diagnostics - Version %scriptVersion% ===
echo.
echo -- Collecting System Information --
call :CollectSystemInfo
echo.
echo -- Checking GPU Information --
call :CheckGPU
echo.
echo -- Checking Python and PyTorch --
call :CheckPython
echo.
echo -- Checking HIP Installation --
call :CheckHIP
echo.
echo -- Generating HTML Report --
call :GenerateHTML
echo.
echo === Comprehensive Diagnostics Complete ===
goto :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: FUNCTIONS
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:CreateDiagDir
echo [%date% %time%] Starting: CreateDiagDir >> %error_log%
:: Create the base directory if it does not exist
if not exist "C:\_LLMDiag" (
    mkdir "C:\_LLMDiag" 2>>%error_log%
    if errorlevel 1 (
        echo Failed to create C:\_LLMDiag. Exiting. >> %error_log%
        echo Failed to create C:\_LLMDiag.  The script will now exit.
        exit /b 1
    )
)

set /a counter=1
:checkDir
if not exist "C:\_LLMDiag\LLMDiag%counter%" (
    set "diagDir=C:\_LLMDiag\LLMDiag%counter%"
    goto createDir
)
set /a counter+=1
goto checkDir

:createDir
echo Creating diagnostic directory: %diagDir%
mkdir "%diagDir%" 2>>%error_log%
cd /d "%diagDir%" 2>>%error_log%
echo Successfully created directory: %diagDir%
echo [%date% %time%] Completed: CreateDiagDir >> %error_log%
goto :eof


:CollectSystemInfo
echo [%date% %time%] Starting: CollectSystemInfo >> %error_log%
echo Collecting CPU, OS, Memory, Environment, and Path information...
echo === CPU Information === > system.txt
wmic cpu get Name, NumberOfCores, NumberOfLogicalProcessors /format:list >> system.txt 2>>%error_log%
echo. >> system.txt 2>>%error_log%

echo === Operating System Information === >> system.txt 2>>%error_log%
ver >> system.txt 2>>%error_log%
echo. >> system.txt 2>>%error_log%

echo === Memory Information === >> system.txt 2>>%error_log%
wmic ComputerSystem get TotalPhysicalMemory /value | findstr "=" >> system.txt 2>>%error_log%
echo. >> system.txt 2>>%error_log%

echo === Environment Variables === >> system.txt 2>>%error_log%
reg query "HKCU\Environment" >> system.txt 2>>%error_log%
echo. >> system.txt 2>>%error_log%

echo === System Path === >> system.txt 2>>%error_log%
path >> system.txt 2>>%error_log%

echo Successfully saved system information to %cd%\system.txt >> %error_log%
echo [%date% %time%] Completed: CollectSystemInfo >> %error_log%
goto :eof

:CheckGPU
echo [%date% %time%] Starting: CheckGPU >> %error_log%
echo Checking GPU driver information...
echo === GPU Information === > gpu.txt
wmic path win32_VideoController get Name, DriverVersion >> gpu.txt 2>>%error_log%
echo Successfully saved GPU information to %cd%\gpu.txt >> %error_log%
echo [%date% %time%] Completed: CheckGPU >> %error_log%
goto :eof

:CheckPython
echo [%date% %time%] Starting: CheckPython >> %error_log%
echo Checking Python and PyTorch...
where python >nul 2>nul
if %errorlevel% equ 0 (
    echo === Python Information === > python.txt
    python --version >> python.txt 2>&1
    python -c "import torch" >nul 2>&1
    if %errorlevel% equ 0 (
        python -c "import torch; print('PyTorch Version:', torch.__version__); print('CUDA Available:', torch.cuda.is_available()); print('CUDA Version:', torch.version.cuda if torch.cuda.is_available() else 'N/A'); print('Number of GPUs:', torch.cuda.device_count() if torch.cuda.is_available() else 0)" >> python.txt 2>&1
    ) else (
        echo Python is installed, but PyTorch is not installed. >> python.txt
    )
) else (
    echo Python is not installed or not in PATH > python.txt
)
echo Successfully saved Python status to %cd%\python.txt >> %error_log%
echo [%date% %time%] Completed: CheckPython >> %error_log%
goto :eof


:CheckHIP
echo [%date% %time%] Starting: CheckHIP >> %error_log%
echo Checking for HIP installation...
where hipinfo >nul 2>nul
if %errorlevel% equ 0 (
echo HIP is installed, collecting information...
hipinfo > hipinfo.txt 2>>%error_log%
) else (
echo HIP is not installed or not in PATH > hipinfo.txt
)
echo Successfully saved HIP status to %cd%\hipinfo.txt >> %error_log%
echo [%date% %time%] Completed: CheckHIP >> %error_log%
goto :eof

:GenerateHTML
echo [%date% %time%] Starting: GenerateHTML >> %error_log%
echo Generating HTML report...
> report.html (
echo ^<!DOCTYPE html^>
echo ^<html lang="en"^>
echo ^<head^>
echo ^<meta charset="UTF-8"^>
echo ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo ^<title^>LLM Diagnostics Report^</title^>
echo ^<style^>
echo body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }
echo h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
echo h2 { color: #2980b9; margin-top: 20px; }
echo pre { background-color: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; }
echo .container { max-width: 1200px; margin: 0 auto; }
echo .links { margin-top: 30px; padding: 15px; background-color: #e9f7fe; border-radius: 5px; }
echo .links a { display: inline-block; margin-right: 15px; padding: 10px 15px; background-color: #3498db; color: white; text-decoration: none; border-radius: 4px; }
echo .links a:hover { background-color: #2980b9; }
echo .info-box { background-color: #f0f0f0; border-left: 4px solid #3498db; padding: 10px; margin-bottom: 15px; }

echo ^</style^>
echo ^</head^>
echo ^<body^>
echo ^<div class="container"^>
echo ^<h1^>LLM Diagnostics Report - Version %scriptVersion%^</h1^>
echo ^<p class="info-box"^>Report generated on: %date% at %time% in directory: %diagDir%^</p^>
)

:: Add sections individually
echo Adding sections to HTML...
echo ^<h2^>System Information^</h2^> >> report.html
echo ^<pre^> >> report.html
type system.txt >> report.html 2>nul
echo ^</pre^> >> report.html

echo ^<h2^>GPU Information^</h2^> >> report.html
echo ^<pre^> >> report.html
type gpu.txt >> report.html 2>nul
echo ^</pre^> >> report.html

echo ^<h2^>Python and PyTorch Information^</h2^> >> report.html
echo ^<pre^> >> report.html
if exist python.txt (
type python.txt >> report.html 2>nul
) else (
echo Python information not available >> report.html
)
echo ^</pre^> >> report.html

echo ^<h2^>HIP Information^</h2^> >> report.html
echo ^<pre^> >> report.html
type hipinfo.txt >> report.html 2>nul
echo ^</pre^> >> report.html

echo ^<h2^>Diagnostics Log^</h2^> >> report.html
echo ^<pre^> >> report.html
type %error_log% >> report.html 2>nul
echo ^</pre^> >> report.html

>> report.html (
echo ^<div class="links"^>
echo ^<h2^>LLM Interfaces^</h2^>
echo ^<a href="http://localhost:3000" target="_blank"^>OpenWebUI Interface^</a^>
echo ^<a href="http://localhost:3001" target="_blank"^>AnythingLLM Desktop^</a^>
echo ^</div^>
echo ^</div^>
echo ^</body^>
echo ^</html^>
)
echo [%date% %time%] Completed: GenerateHTML >> %error_log%
goto :eof

:OpenHTML
echo [%date% %time%] Starting: OpenHTML >> %error_log%
echo Opening HTML report: %diagDir%\report.html
start "" "%diagDir%\report.html" 2>>%error_log%
echo If the report doesn't open automatically, please navigate to %diagDir%\report.html manually.
echo [%date% %time%] Completed: OpenHTML >> %error_log%
goto :exit

:exit
echo Exiting the LLM Diagnostics Tool.
endlocal
exit /b 0
