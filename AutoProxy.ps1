#-------------------------------------
# Proxy autoselect
# Written by: shimkhani@icloud.com; September'2017
# 
# Input parameters: -action "on" ; "off"  Not selecting a parameter will invoke auto-detect.
# Starting requirements: Ensure the EventLog source: "PS_AutoProxy" is registered otherwise it will throw errors
# Todo: 
#    1.Pass in EventID to writelogs - 0001 proxy on; 0002; proxy off; 0000 auto
#-------------------------------------

#Start script:
param (
    [string]$action
)

#Configurations:
$WorkNetWorkIdentifier = "an internal network name such as AD"


#Process:
function Refresh-System
{
    $signature = @'
    [DllImport("wininet.dll", SetLastError = true, CharSet=CharSet.Auto)]
    public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
'@

    $INTERNET_OPTION_SETTINGS_CHANGED   = 39
    $INTERNET_OPTION_REFRESH            = 37
    $type = Add-Type -MemberDefinition $signature -Name wininet -Namespace pinvoke -PassThru
    $a = $type::InternetSetOption(0, $INTERNET_OPTION_SETTINGS_CHANGED, 0, 0)
    $b = $type::InternetSetOption(0, $INTERNET_OPTION_REFRESH, 0, 0)
   # return $a -and $b
}

function WriteToLogs([String]$MessageTxt)
{
    Write-EventLog -LogName "Application" -Source "PS_AutoProxy" -EventID 0000 -EntryType Information -Message $MessageTxt 
}

function TestForWorkNetwork()
{
    $ConnectionResult = Test-Connection -Cn $WorkNetWorkIdentifier -BufferSize 1 -Count 1 -ea 0 -Quiet
    return $ConnectionResult
}

function SetProxyRegSetting([int]$valueToSet)
{
    set-itemproperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -value $valueToSet
}

switch ($action.ToLower())
{
    "on" {
            WriteToLogs("Instructed to turn ON the proxy")
            SetProxyRegSetting(1)
            Refresh-System
         }
    "off" {
            WriteToLogs("Instructed to turn OFF the proxy")
            SetProxyRegSetting(0)
            Refresh-System
          }
    default {
                if (TestForWorkNetwork -eq true){
                 WriteToLogs("Instructed to AUTO select the proxy :: Setting to on")
                 SetProxyRegSetting(1)
                 }
                else { 
                 WriteToLogs("Instructed to AUTO select the proxy :: Setting to off")
                 SetProxyRegSetting(0)
                }
                
            Refresh-System
            }
}

#Exit script:
#Start-Sleep -s 1
Remove-Variable -Name * -ErrorAction SilentlyContinue
