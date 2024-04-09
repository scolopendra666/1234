@echo off
set _PRG_DIR=%~dp0

set _PRGRUNMODE=false


set START_CONFLUENCE_JAVA_OPTS=-Datlassian.plugins.startup.options="%*%"

:Loop
IF "%1"=="" GOTO Continue
IF "%1" == "/?" (
	"%_PRG_DIR%display-help.bat"
    GOTO:END
)
IF "%1" == "/help" (
	"%_PRG_DIR%display-help.bat"
    GOTO:END
)
IF "%1" == "--help" (
	"%_PRG_DIR%display-help.bat"
    GOTO:END
)
IF "%1" == "/h" (
	"%_PRG_DIR%display-help.bat"
    GOTO:END
)
IF "%1" == "-h" (
	"%_PRG_DIR%display-help.bat"
    GOTO:END
)
echo.%1 | findstr /C:"disablealladdons" >nul && (
	echo Disabling all user installed addons
	)
echo.%1 | findstr /C:"disableaddons" >nul && (
	echo Disabling specified plugins
	)
IF "%1" == "/fg" (
	set _PRGRUNMODE=true
)
IF "%1" == "run" (
	set _PRGRUNMODE=true
)

SHIFT
GOTO Loop
:Continue

if "%_PRGRUNMODE%" == "true" GOTO EXECSTART
	echo.
	echo To run Confluence in the foreground, start the server with start-confluence.bat /fg


:EXECSTART
if "%_PRGRUNMODE%" == "true" GOTO EXECRUNMODE
	"%_PRG_DIR%startup.bat"  %1 %2 %3 %4 %5 %6 %7 %8 %9
	GOTO END

:EXECRUNMODE
	"%_PRG_DIR%catalina.bat"  run %2 %3 %4 %5 %6 %7 %8 %9
	GOTO END

:END
