@echo off
setlocal

rem Use this script to start a standalone Synchrony process on Windows (for use with Confluence Data Center only)
rem Replace the <values> below with appropriate values for your environment.
rem For more information about the Synchrony system properties you can configure see:
rem https://confluence.atlassian.com/display/DOC/Configuring+Synchrony+for+Data+Center

rem Parse the Synchrony home folder from the script location
set SYNCHRONY_HOME=%~dp0

rem ################################# Parameters to configure ##################################

rem IP address or hostname of this Synchrony node -- should be reachable by other nodes
set SERVER_IP=<SERVER_IP>

rem Your Confluence database information (can be copied from confluence.cfg.xml in your Confluence home directory)
set DATABASE_URL=<YOUR_DATABASE_URL>
set DATABASE_USER=<DB_USERNAME>

rem We recommend setting your password with the environment variable SYNCHRONY_DATABASE_PASSWORD.
rem This allows Synchrony to detect sensitive information without making it visible in the process command information.
rem However, you may also hardcode your password here.
set DATABASE_PASSWORD=<DB_PASSWORD>

rem rem Uncomment this section if you want to do node discovery using TCP/IP
rem rem Comma separated list of IP addresses for each cluster node
rem set TCPIP_MEMBERS=<TCPIP_MEMBERS>
rem set CLUSTER_JOIN_PROPERTIES=-Dcluster.join.type=tcpip -Dcluster.join.tcpip.members=%TCPIP_MEMBERS%

rem rem Uncomment this section if you want to do node discovery in AWS
rem set ATL_HAZELCAST_NETWORK_AWS_TAG_KEY=<AWS_TAG_KEY>
rem set ATL_HAZELCAST_NETWORK_AWS_TAG_VALUE=<AWS_TAG_VALUE>
rem set CLUSTER_JOIN_PROPERTIES=-Dcluster.join.type=aws -Dcluster.join.aws.tag.key=%ATL_HAZELCAST_NETWORK_AWS_TAG_KEY% -Dcluster.join.aws.tag.value=%ATL_HAZELCAST_NETWORK_AWS_TAG_VALUE%

rem rem Uncomment this section if you want to do node discovery using multicast
rem set CLUSTER_JOIN_PROPERTIES=-Dcluster.join.type=multicast

rem Locations of the synchrony-standalone.jar and database driver jar
set DATABASE_DRIVER_PATH=<JDBC_DRIVER_PATH>
set SYNCHRONY_JAR_PATH=<PATH_TO_SYNCHRONY_STANDALONE_JAR>

rem URL that the browser uses to contact Synchrony -- should include the context path
set SYNCHRONY_URL=<SYNCHRONY_URL>

rem Optionally override default system property values here. Consult docs for more optional properties
rem	Example usage: set OPTIONAL_OVERRIDES=-Dsynchrony.port=8099 -Dcluster.listen.port=5701
set OPTIONAL_OVERRIDES=

rem rem Uncomment this section if you're running Confluence in an IPv6 environment
rem set OPTIONAL_OVERRIDES=%OPTIONAL_OVERRIDES% -Dhazelcast.prefer.ipv4.stack=false

rem rem Uncomment this section to specify an executable batch script to source for environment variables
rem rem Useful for passing sensitive information (i.e. passwords) to Synchrony
rem rem Use this method when setting environment variables for Synchrony running as a service
rem rem Example of file contents:
rem rem	 	set SYNCHRONY_DATABASE_USERNAME=<DB_USERNAME>
rem rem		set SYNCHRONY_DATABASE_PASSWORD=<DB_PASSWORD>
rem set SYNCHRONY_ENV_FILE=<PATH_TO_ENV_FILE>

rem Path to file where Synchrony PID will be stored
rem If you change this, you'll also need to set this value in 'stop-synchrony.bat'
set SYNCHRONY_PID_FILE=%SYNCHRONY_HOME%synchrony.pid

rem Optionally configure JVM
set JAVA_BIN=java
set JAVA_OPTS=-Xss2048k -Xmx2g

rem #############################################################################################

set _PRGRUNMODE=false
set _PROCESSNAME=Atlassian-Synchrony

if "%1" == "" goto :CHECKPID
if "%1" == "/fg" (
	set _PRGRUNMODE=true
	goto :CHECKPID
)

rem check for help prompt or if user has tried to run the script without editing it
if "%1" == "/?" goto :HELP
if "%1" == "/help" goto :HELP
if "%1" == "--help" goto :HELP
if "%1" == "/h" goto :HELP
if "%1" == "-h" goto :HELP
if "%CLUSTER_JOIN_PROPERTIES%" == "" goto :HELP

:HELP
echo Edit this file to provide Synchrony information on how to run. 
echo Then simply run 'start-synchrony.bat' or 'start-synchrony.bat /fg' (to run the process in the foreground)  
echo For more information about configuring Synchrony, visit https://confluence.atlassian.com/display/DOC/Configuring+Synchrony+for+Data+Center
goto :END

:CHECKPID
set SYNCHRONY_PID_FILE="%SYNCHRONY_PID_FILE:"=%"
if not exist %SYNCHRONY_PID_FILE% goto :GETENV

set /p PID=<%SYNCHRONY_PID_FILE%
if not "%PID%" == "" (
	tasklist /fi "pid eq %PID%" | find "%PID%" >NUL
	if not ERRORLEVEL 1 (
		echo Synchrony appears to still be running with PID %PID%. Start aborted.
		echo If the following process is not a Synchrony process, remove %SYNCHRONY_PID_FILE% and try again.
		tasklist /fi "pid eq %PID%"
		goto :END
	)
)
	
echo Please remove %SYNCHRONY_PID_FILE% and try to start Synchrony again.
goto :END

rem try to source env file if it exists
:GETENV
if not defined SYNCHRONY_ENV_FILE goto :DEFPROPS

set SYNCHRONY_ENV_FILE="%SYNCHRONY_ENV_FILE:"=%"
if exist %SYNCHRONY_ENV_FILE% (
	call %SYNCHRONY_ENV_FILE% >NUL
	if ERRORLEVEL 1 (
		echo Synchrony environment file %SYNCHRONY_ENV_FILE% exists, but isn't executable.
		echo If you want to set Synchrony properties this way, stop Synchrony and adjust the file format accordingly.
	)
)

:DEFPROPS
set _RUNJAVA=%JAVA_BIN% %JAVA_OPTS%
set SYNCHRONY_OPTS=-classpath "%SYNCHRONY_JAR_PATH:"=%";"%DATABASE_DRIVER_PATH:"=%"
set SYNCHRONY_OPTS=%SYNCHRONY_OPTS% -Dsynchrony.service.url=%SYNCHRONY_URL%
set SYNCHRONY_OPTS=%SYNCHRONY_OPTS% -Dsynchrony.bind=%SERVER_IP%
set SYNCHRONY_OPTS=%SYNCHRONY_OPTS% %CLUSTER_JOIN_PROPERTIES%
set SYNCHRONY_OPTS=%SYNCHRONY_OPTS% %OPTIONAL_OVERRIDES%

if not defined SYNCHRONY_DATABASE_URL set SYNCHRONY_OPTS=%SYNCHRONY_OPTS% -Dsynchrony.database.url=%DATABASE_URL%
if not defined SYNCHRONY_DATABASE_USERNAME set SYNCHRONY_OPTS=%SYNCHRONY_OPTS% -Dsynchrony.database.username=%DATABASE_USER%
if not defined SYNCHRONY_DATABASE_PASSWORD set SYNCHRONY_OPTS=%SYNCHRONY_OPTS% -Dsynchrony.database.password=%DATABASE_PASSWORD%

:RUN
if %_PRGRUNMODE% == true (
	%_RUNJAVA% %SYNCHRONY_OPTS% synchrony.core sql
	goto :END
)

echo (To run Synchrony in the foreground, start the process with start-synchrony.bat /fg) 
start "%_PROCESSNAME%" %_RUNJAVA% %SYNCHRONY_OPTS% synchrony.core sql

:GETPID
for /f "tokens=*" %%i in ('wmic process where "name=\"java.exe\"" get processid^,commandline ^| findstr /i synchrony.core') do call :PARSEPID %%i
goto :LOGSTART

:PARSEPID
if "%~2" == "" (
	set PID=%1
	goto :END
) else (
	shift
	goto :PARSEPID
)

:LOGSTART
echo %PID%> %SYNCHRONY_PID_FILE%
echo Starting Synchrony with PID %PID%...
echo Binding: %SERVER_IP%
echo Please wait 30 seconds, then check this heartbeat URL in your browser for an 'OK': %SYNCHRONY_URL%/heartbeat

:END