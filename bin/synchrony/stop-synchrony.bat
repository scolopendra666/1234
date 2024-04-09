@echo off
setlocal

rem Use this script to stop a standalone Synchrony process on Windows (for use with Confluence Data Center only)
rem Replace the <values> below with appropriate values for your environment.
rem For more information about the Synchrony system properties you can configure see:
rem https://confluence.atlassian.com/display/DOC/Configuring+Synchrony+for+Data+Center

rem Parse the Synchrony home folder from the script location
set SYNCHRONY_HOME=%~dp0

rem ################################# Parameters to configure ##################################

rem Path to file where Synchrony PID is stored, as set in 'start-synchrony.bat'
rem Only change this if you've changed the value in 'start-synchrony.bat'
set SYNCHRONY_PID_FILE=%SYNCHRONY_HOME%synchrony.pid

rem #############################################################################################

set SYNCHRONY_PID_FILE="%SYNCHRONY_PID_FILE:"=%"
if not exist %SYNCHRONY_PID_FILE% goto :ABORT

set /a SLEEP=5
set /p PID=<%SYNCHRONY_PID_FILE%
if "%PID%" == "" goto :ABORT

:CHECKPROC
for /f "tokens=*" %%i in ('2^>nul wmic process where "processid=%PID%" get commandline ^| findstr /i synchrony.core') do goto :STOPPROC
goto :ABORT

:STOPPROC
taskkill /pid %PID% >NUL
if not errorlevel 1 (
	del %SYNCHRONY_PID_FILE%
	if errorlevel 1 echo The PID file could not be removed or cleared.
	echo Synchrony process with pid %PID% stopped.
	goto :END
)

if %SLEEP% gtr 0 (
	ping 127.0.0.1 -n 2 >NUL
)

if %SLEEP% equ 0 (
	echo Synchrony process did not stop in time. Attempting to signal the process to stop through OS signal.
	taskkill /f /pid %PID% >NUL
	del %SYNCHRONY_PID_FILE%
	goto :END
)

set /a SLEEP=%SLEEP% - 1
goto :STOPPROC

:ABORT
echo WARNING: Either the pid file %SYNCHRONY_PID_FILE% is missing or a Synchrony process with the corresponding PID was not found. Aborting!

:END