<#
.SYNOPSIS
Iterates through a XenApp 6.5 Application list and recomemnds cleanup actions to reduce the number of users/groups assigned to a published application.
.DESCRIPTION
Iterates through a XenApp 6.5 Application list and recomemnds cleanup actions to reduce the number of users/groups assigned to a published application. 
The recommended actions will output to a txt file. If addADGroupList is present, then the script will create a txt file of new AD groups.
It is recommended that this script be run as a Citrix admin. 
.PARAMETER XMLBrokers
Optional parameter. Which Citrix XMLBroker(s) (farm) to query. Can be a list separated by commas.
.PARAMETER addADGroupList
Optional switch parameter. If present, a separate txt file of new AD groups will be written.
.EXAMPLE
PS C:\PSScript > .\cleanup-xaappsandaccts.ps1
Will use all default values.
.EXAMPLE
PS C:\PSScript > .\cleanup-xaappsandaccts.ps1 -XMLBrokers "XMLBROKER"
Will use "XMLBROKER" to query XenApp farm.
.NOTES
NAME        :  cleanup-xaappsandaccts.ps1
VERSION     :  1.02
LAST UPDATED:  2/13/2017
AUTHOR      :  Alain Assaf
.LINK
http://www.linkedin.com/in/alainassaf/
http://wagthereal.com
https://blogs.technet.microsoft.com/heyscriptingguy/2014/05/07/powershell-looping-basics-of-the-break/
http://powershelleverydayfaq.blogspot.com/2013/08/how-to-use-write-verbose-with-object.html
.INPUTS
None
.OUTPUTS
None
#>

Param(
 [parameter(Position = 0, Mandatory=$False )]
 [ValidateNotNullOrEmpty()]
 $XMLBrokers="CITRIXXMLBROKER", # Change to hardcode a default value for your Delivery Controllers

 [parameter(Position = 1, Mandatory=$False )] 	
 [ValidateNotNullOrEmpty()]
 [switch]$addADGroupList

) 

#Constants
$datetime = get-date -format "MM-dd-yyyy_HH-mm"
$PSModules = ("activedirectory")
$PSSnapins = ("*citrix*")
#$ErrorActionPreference= 'silentlycontinue'
$accountpattern = '\w\w\w\d\d\d\d\d\w\w\w' # Change to a regular expression that matches your username naming convention
$outputfile = "c:\temp\xaappfixes_" + $datetime.Tostring() + ".txt"
$adgroupfile = "c:\temp\xaappgroups_" + $datetime.Tostring() + ".txt"

### START FUNCTION: get-mymodule #####################################################
Function Get-MyModule {
    Param([string]$modules)
    $ErrorActionPreference= 'silentlycontinue'
        foreach ($mod in $modules.Split(",")) {
            if(-not(Get-Module -name $mod)) {
                if(Get-Module -ListAvailable | Where-Object { $_.name -like $mod }) {
                    Import-Module -Name $mod
                } else {
                    write-warning "$mod PowerShell Module not available."
                    write-warning "Please run this script from a system with the $mod PowerShell Module is installed."
                    exit 1
                }
            }
        }
}
### END FUNCTION: get-mymodule #####################################################
 
### START FUNCTION: get-mysnapin ###################################################
Function Get-MySnapin {
    Param([string]$snapins)
        $ErrorActionPreference= 'silentlycontinue'
        foreach ($snap in $snapins.Split(",")) {
            if(-not(Get-PSSnapin -name $snap)) {
                if(Get-PSSnapin -Registered | Where-Object { $_.name -like $snap }) {
                    add-PSSnapin -Name $snap
                    $true
                }                                                                           
                else {
                    write-warning "$snap PowerShell Cmdlet not available."
                    write-warning "Please run this script from a system with the $snap PowerShell Cmdlet installed."
                    exit 1
                }                                                                           
            }                                                                                                                                                                  
        }
}
### END FUNCTION: get-mysnapin #####################################################


### START FUNCTION: test-port ######################################################
# Function to test RDP availability
# Written by Aaron Wurthmann (aaron (AT) wurthmann (DOT) com)
function Test-Port{
    Param([string]$srv=$strhost,$port=3389,$timeout=300)
    $ErrorActionPreference = "SilentlyContinue"
    $tcpclient = new-Object system.Net.Sockets.TcpClient
    $iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
    $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
    if(!$wait) {
        $tcpclient.Close()
        Return $false
    } else {
        $error.Clear()
        $tcpclient.EndConnect($iar) | out-Null
        Return $true
        $tcpclient.Close()
    }
}
### END FUNCTION: test-port ########################################################


#Import Module(s) and Snapin(s)
get-mymodule $PSModules
get-MySnapin $PSSnapins

#Find an XML Broker that is up
$DC = $XMLBrokers.Split(",")
foreach ($broker in $DC) {
    if ((Test-Port $broker) -and (Test-Port $broker -port 1494) -and (Test-Port $broker -port 2598))  {
        $XMLBroker = $broker
        break
    }
}
  
# Get list of applications
$XAApps = Get-XAApplicationReport -ComputerName $xmlbroker * | where {$_.Enabled -eq $true} | select browsername,accounts 

# Application loop
foreach ($app in $XAApps) {
    write-verbose $app.browsername
    write-verbose (($app.Accounts | select accountname).accountname | out-string)
    $isUser = $null
    $isGroup = $null
    # Application account(s) loop
    foreach ($acct in $app.Accounts) {
        if ($acct.AccountName -match $accountpattern) {
            Write-verbose "$acct is a user account"
            $isUser += $acct.AccountName.ToString() + ','
        } else {
            write-verbose "$acct is an AD group"
            if ($acct -match 'Citrix Admins') {
                write-verbose "AD Group is Citrix Admins"
            } else {
                $isGroup += $acct.AccountName.ToString() + ','
            }
        }
    }
    if ($isUser -ne $null) {
        $isUser = $isUser.TrimEnd(",")
        if ($isGroup -ne $null) {
            $isGroup = $isGroup.TrimEnd(",")
            $usrCount = 0
            foreach ($grp in $isGroup.split(",")) {
                $grpUsers = (Get-ADGroupMember $grp | select samaccountname).samaccountname
                foreach ($usr in $isUser.split(",")) {
                    if ($grpUsers -contains $usr) {
                        $xaapp =  $app.browsername.ToString()
                        write-warning "$usr is already a member of $grp. REMOVE from $xaapp"
                        add-content $outputfile -value "$usr should be removed from $xaapp"
                        $usrCount++;
                    }
                }
            }
            if ($usrCount -eq 0) {
                $xaapp =  $app.browsername.ToString()
                write-warning "$isuser is/are NOT a member of any '$xaapp' groups."
                add-content $outputfile -value "$isuser should be added to new CTX-$xaapp group"
                if ($addADGroupList) {add-content $adgroupfile -value "CTX-$xaapp"}
            }
        } else {
            $xaapp =  $app.browsername.ToString()
            Write-warning "$xaapp needs an AD Group. For example --- CTX-$xaapp ---"
            add-content $outputfile -value "$xaapp needs an AD Group. For example --- CTX-$xaapp ---"
            if ($addADGroupList) {add-content $adgroupfile -value "CTX-$xaapp"}
        }
    } else {
        if ($isGroup -ne $null) {
            $isGroup = $isGroup.TrimEnd(",")
            if ($isGroup.count -ge 1) {
                $xaapp =  $app.browsername.ToString()
                Write-warning "$xaapp needs a single AD Group. For example --- CTX-$xaapp ---"
                add-content $outputfile -value "$xaapp needs an AD Group. For example --- CTX-$xaapp ---"
                if ($addADGroupList) {add-content $adgroupfile -value "CTX-$xaapp"}
            }
        } else {
            $xaapp =  $app.browsername.ToString()
            Write-warning "$xaapp has no users or groups assigned. It needs an AD Group. For example --- CTX-$xaapp ---"
            add-content $outputfile -value "$xaapp needs an AD Group. For example --- CTX-$xaapp ---"
            if ($addADGroupList) {add-content $adgroupfile -value "CTX-$xaapp"}
        }
    }
}