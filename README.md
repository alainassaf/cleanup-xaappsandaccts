# cleanup-xaappsandaccts
Recommends account/group clean-up actions for published applications

#Contributions to this script
I'd like to highlight the posts that helped me write this scrip below.
* https://blogs.technet.microsoft.com/heyscriptingguy/2014/05/07/powershell-looping-basics-of-the-break/
* http://powershelleverydayfaq.blogspot.com/2013/08/how-to-use-write-verbose-with-object.html    

# get-help .\cleanup-xaappsandaccts.ps1 -full

NAME
    cleanup-xaappsandaccts.ps1
    
SYNOPSIS
    Iterates through a XenApp 6.5 Application list and recomemnds cleanup actions to reduce the number of users/groups assigned to a published application.
    
SYNTAX
    cleanup-xaappsandaccts.ps1 [[-XMLBrokers] <Object>] [[-addADGroupList]] [<CommonParameters>]
    
DESCRIPTION
    Iterates through a XenApp 6.5 Application list and recomemnds cleanup actions to reduce the number of users/groups assigned to a published application. 
    The recommended actions will output to a txt file. If addADGroupList is present, then the script will create a txt file of new AD groups.
    It is recommended that this script be run as a Citrix admin.
    
PARAMETERS
    -XMLBrokers <Object>
        Optional parameter. Which Citrix XMLBroker(s) (farm) to query. Can be a list separated by commas.
        
        Required?                    false
        Position?                    1
        Default value                CITRIXXMLBROKER
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -addADGroupList [<SwitchParameter>]
        Optional switch parameter. If present, a separate txt file of new AD groups will be written.
        
        Required?                    false
        Position?                    2
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    None
    
OUTPUTS
    None
    
NOTES
    
        NAME        :  cleanup-xaappsandaccts.ps1
        VERSION     :  1.02
        LAST UPDATED:  2/13/2017
        AUTHOR      :  Alain Assaf
    
    -------------------------- EXAMPLE 1 --------------------------
    PS C:\PSScript >.\cleanup-xaappsandaccts.ps1
    
    Will use all default values.
    
    -------------------------- EXAMPLE 2 --------------------------
    PS C:\PSScript >.\cleanup-xaappsandaccts.ps1 -XMLBrokers "XMLBROKER"
    
    Will use "XMLBROKER" to query XenApp farm.
    
# Legal and Licensing
The cleanup-xaappsandaccts.ps1 script is licensed under the [MIT license][].

[MIT license]: LICENSE

# Want to connect?
* LinkedIn - https://www.linkedin.com/in/alainassaf
* Twitter - http://twitter.com/alainassaf
* Wag the Real - my blog - https://wagthereal.com
* Edgesightunderthehood - my other - blog https://edgesightunderthehood.com

# Help
I welcome any feedback, ideas or contributors.
