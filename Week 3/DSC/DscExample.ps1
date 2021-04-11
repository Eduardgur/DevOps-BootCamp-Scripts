
<#

    First enable share on the mof dir and set permissions 
    add to dmz
    open 5985 on target
#>

Set-AzVMExtension -ExtensionName "DSC" -ResourceGroupName "Test" -VMName "AppVM" `
    -Publisher "Microsoft.Powershell" -ExtensionType "DSC" -TypeHandlerVersion 2.83 `
    -Location "eastus" 

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "104.211.38.2"
            PSDscAllowPlainTextPassword = $true
        }
    )
}


configuration TestDSC {
    param(
        # [Parameter(Mandatory=$true)]
        # [ValidateNotNullorEmpty()]
        [PsCredential] $Credential
    )
    
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

    Node $AllNodes.NodeName {
        File Test {
            Credential      = $Credential
            DestinationPath = "C:\a.ps1"
            SourcePath      = "\\77.126.91.224\week3\a.ps1"
            Ensure          = "Present"
            Type            = "File"
            Checksum        = "modifiedDate"
            Force           = $true
            MatchSource     = $true
        } 

        Script RunHelloWorldScript {       
            SetScript  = { "c:\a.ps1" }
            TestScript = { $false } 
            GetScript  = { @{ Result = (Get-Content "c:\1.txt") } }
        }
    }
}

TestDSC -OutputPath ".\" -Verbose -Cred (Get-Credential) -ConfigurationData $ConfigurationData

Start-DscConfiguration -path "E:\source\repos\DevOps\Week 3\" -ComputerName "104.211.38.2" -Credential $VMCred -Force -wait -verbose

