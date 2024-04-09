rem Create a timestamp with date and time, replacing ' ' with '0', '/' with '-' and ':' with '-'
set atlassian_timestamp=%DATE:~-4%.%DATE:~4,2%.%DATE:~7,2%_%TIME:~0,2%.%TIME:~3,2%.%TIME:~6,2%
echo %atlassian_timestamp%
set atlassian_timestamp=%atlassian_timestamp: =0%
set atlassian_timestamp=%atlassian_timestamp:/=-%
set atlassian_timestamp=%atlassian_timestamp::=-%
echo %atlassian_timestamp%

rem Calculate offset to ..\logs directory
set atlassian_logsdir=%~dp0..\logs

rem IMPORTANT NOTE: Only set JAVA_HOME or JRE_HOME above this line
rem Get standard Java environment variables
if exist "%CATALINA_HOME%\bin\setjre.bat" goto setJre
echo Cannot find "%CATALINA_HOME%\bin\setjre.bat"
echo This file is needed to run this program
goto end
:setJre
call "%CATALINA_HOME%\bin\setjre.bat" %1
if errorlevel 1 goto end

echo "---------------------------------------------------------------------------"
echo "Using Java: %JRE_HOME%\bin\java.exe"
for /f %%i in ('"%JRE_HOME%\bin\java.exe" -jar %CATALINA_HOME%\bin\confluence-context-path-extractor.jar %CATALINA_HOME%') do set CONFLUENCE_CONTEXT_PATH=%%i
"%JRE_HOME%\bin\java.exe" -jar %CATALINA_HOME%\bin\synchrony-proxy-watchdog.jar %CATALINA_HOME%
echo "---------------------------------------------------------------------------"

rem Set the JVM arguments used to start Confluence.
rem For a description of the vm options of jdk 8, see:
rem http://www.oracle.com/technetwork/java/javase/tech/vmoptions-jsp-140102.html
rem For a description of the vm options of jdk 11, see:
rem https://docs.oracle.com/en/java/javase/11/tools/java.html
set CATALINA_OPTS=-XX:+IgnoreUnrecognizedVMOptions %CATALINA_OPTS%
set CATALINA_OPTS=-XX:-PrintGCDetails -XX:+PrintGCDateStamps -XX:-PrintTenuringDistribution %CATALINA_OPTS%
set CATALINA_OPTS=-Xlog:gc+age=debug:file="%atlassian_logsdir%\gc-%atlassian_timestamp%.log"::filecount=5,filesize=2M %CATALINA_OPTS%
set CATALINA_OPTS=-XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=2M %CATALINA_OPTS%
set CATALINA_OPTS=-Xloggc:"%atlassian_logsdir%\gc-%atlassian_timestamp%.log" %CATALINA_OPTS%
set CATALINA_OPTS=-XX:G1ReservePercent=20 %CATALINA_OPTS%
set CATALINA_OPTS=-Djava.awt.headless=true %CATALINA_OPTS%
set CATALINA_OPTS=-Datlassian.plugins.enable.wait=300 %CATALINA_OPTS%
set CATALINA_OPTS=-Xms1024m -Xmx1024m -XX:+UseG1GC %CATALINA_OPTS%
set CATALINA_OPTS=-Dsynchrony.enable.xhr.fallback=true %CATALINA_OPTS%
set CATALINA_OPTS=-Dorg.apache.tomcat.websocket.DEFAULT_BUFFER_SIZE=32768 %CATALINA_OPTS%
set CATALINA_OPTS=-Djava.locale.providers=JRE,SPI,CLDR %CATALINA_OPTS%
set CATALINA_OPTS=%START_CONFLUENCE_JAVA_OPTS% %CATALINA_OPTS%
set CATALINA_OPTS=-Dconfluence.context.path=%CONFLUENCE_CONTEXT_PATH% %CATALINA_OPTS%
set CATALINA_OPTS=-Djdk.tls.server.protocols=TLSv1.1,TLSv1.2 -Djdk.tls.client.protocols=TLSv1.1,TLSv1.2 %CATALINA_OPTS%
set CATALINA_OPTS=-XX:ReservedCodeCacheSize=256m -XX:+UseCodeCacheFlushing %CATALINA_OPTS%


rem Clean up temporary variables
set atlassian_logsdir=
set atlassian_timestamp=

:end
