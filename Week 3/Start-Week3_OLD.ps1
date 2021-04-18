<#
.SYNOPSIS
Completes week 3 project
.DESCRIPTION
Creates:
    1 Resource group
    1 VNet
    2 Network security groups
    2 VMs, first one running the app in a public subnet, second one running the db in a private subnet
.PARAMETER

.EXAMPLE
#>


[cmdletbinding()]
param(
    # [Parameter(Mandatory=$true) ]
    # [string]$Region,
    # [Parameter(Mandatory=$true) ]
    # [string]$RGName
)

$Region = "eastus"
$RGName = "Test"

$VmCred = Get-Credential -Message "Enter a username and password for the virtual machine."


Login-AzAccount

#Checks if Resource group exists, creates it if dosn't
$RGExists = Get-AzResourceGroup -Location $Region -Name -RGName -ErrorAction SilentlyContinue

if(-Not $RGExists){
    Write-Warning "$RGName was not found in $Region, Creating now"

    $RG = New-AzResourceGroup -Location $Region -Name $RGName

    Write-Verbose "$RGName [Resource group] has been created in $Region"
}else{
    Write-Verbose "$RGName has been found in $Region"
}


# Create a virtual network with a front-end subnet and back-end subnet.
$AppSbCfg = New-AzVirtualNetworkSubnetConfig -Name 'App-Subnet' -AddressPrefix '192.168.0.0/24'
$DbSbCfg = New-AzVirtualNetworkSubnetConfig -Name 'Db-Subnet' -AddressPrefix '192.168.1.0/24'
$Vnet = New-AzVirtualNetwork -ResourceGroupName $RGName -Name 'TestVnet' -Location $Region `
    -Subnet $AppSbCfg, $DbSbCfg -AddressPrefix '192.168.0.0/16'


# Create an NSG rule to allow HTTP traffic in from the Internet to the front-end subnet.
$NsgRuleHttp = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-All' -Description 'Allow HTTP' `
    -Access Allow -Protocol Tcp -DestinationPortRange 80 -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * 

# Create an NSG rule to allow HTTP traffic in from the Internet to the front-end subnet.
$NsgRuleWinRM = New-AzNetworkSecurityRuleConfig -Name 'Allow-WinRm-App' -Description 'Allow WinRM' `
    -Access Allow -Protocol Tcp -DestinationPortRange 5985 -Direction Inbound -Priority 1000 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix '192.168.0.0/24' 

$NsgRuleSMB = New-AzNetworkSecurityRuleConfig -Name 'Allow-SMB-APP' -Description 'Allow SMB' `
        -Access Allow -Protocol Tcp -DestinationPortRange 445 -Direction Inbound -Priority 1001 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix '192.168.0.0/24' 

$NsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name 'Allow-SSH-DB' -Description 'Allow WinRM' `
    -Access Allow -Protocol Tcp -DestinationPortRange 22 -Direction Inbound -Priority 1002 `
    -SourceAddressPrefix '192.168.0.0/24' -SourcePortRange * -DestinationAddressPrefix '192.168.1.0/24' 

  # Create an NSG rule to allow SQL traffic from the front-end subnet to the back-end subnet.
$NsgRuleDB = New-AzNetworkSecurityRuleConfig -Name 'Allow-App2Db-HTTP' -Description "Allow App2Db" `
    -Access Allow -Protocol Tcp -DestinationPortRange 5432 -Direction Inbound -Priority 100 `
    -SourceAddressPrefix '192.168.0.0/24' -SourcePortRange * -DestinationAddressPrefix '192.168.1.0/24'  

# Create an NSG rule to allow RDP traffic from the Internet to the back-end subnet.
$NsgRuleRdp = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
    -Access Allow -Protocol Tcp -DestinationPortRange 3389 -Direction Inbound -Priority 200 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * 


# Create a network security group for the front-end subnet.
$AppNsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $Region `
    -Name 'App-Nsg' -SecurityRules $NsgRuleHttp, $NsgRuleRdp, $NsgRuleWinRM, $NsgRuleSMB
# Associate the front-end NSG to the front-end subnet.
Set-AzVirtualNetworkSubnetConfig -Name 'App-Subnet' -VirtualNetwork $Vnet -NetworkSecurityGroup $AppNsg `
    -AddressPrefix '192.168.0.0/24' 

# Create a network security group for back-end subnet.
$DbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $Region `
    -Name "Db-Nsg" -SecurityRules $NsgRuleDB, $NsgRuleSSH
# Associate the back-end NSG to the back-end subnet
Set-AzVirtualNetworkSubnetConfig -Name 'Db-Subnet' -VirtualNetwork $Vnet -NetworkSecurityGroup $DbNsg `
    -AddressPrefix '192.168.0.0/24' 



# Create a public IP address for the web server VM.
$AppVmPublicIP = New-AzPublicIpAddress -ResourceGroupName $RgName -Name 'App-PublicIP' -location $Region -AllocationMethod Dynamic
# Create a NIC for the web server VM.
$AppVmNic = New-AzNetworkInterface -ResourceGroupName $RgName -Location $Region `
    -Name 'App-Nic' -PublicIpAddress $AppVmPublicIP -NetworkSecurityGroup $AppNsg -Subnet $Vnet.Subnets[0]


# $DbVmPublicIP = New-AzPublicIpAddress -ResourceGroupName $RgName -Name 'Db-PublicIP' -location $Region -AllocationMethod Dynamic
$DbVmPrivateIPConfig = New-AzNetworkInterfaceIpConfig -Name 'Db-PrivateIp' -PrivateIpAddress 192.168.1.4 -Subnet $Vnet.Subnets[1]
# Create a NIC for the SQL VM.
$DbVmNic = New-AzNetworkInterface -ResourceGroupName $RgName -Location $Region `
    -Name 'Db-Nic' -IpConfigurationName $DbVmPrivateIPConfig.Name -NetworkSecurityGroup $DbNsg -Subnet $Vnet.Subnets[1] 
    # -PublicIpAddress $DbVmPublicIP
# Check :
# $DiagSa = New-AzStorageAccount -ResourceGroupName $RGName -Name "diagbootstorageaccount" -Location $Region -SkuName Standard_LRS -Kind StorageV2
# Set-AzVMBootDiagnostic -ResourceGroupName $RgName -VM $AppVm -Enable -StorageAccountName "diagbootstorageaccount"

# Create a Web Server VM in the front-end subnet
$AppVmConfig = New-AzVMConfig -VMName 'AppVM' -VMSize 'Standard_B2s' | `
    Set-AzVMOperatingSystem -Windows -ComputerName 'App-Vm' -Credential $VmCred | `
    Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest | `
    Add-AzVMNetworkInterface -Id $AppVmNic.Id

$AppVm = New-AzVM -ResourceGroupName $RgName -Location $Region -VM $AppVmConfig 
Start-AzVM -ResourceGroupName $RGName -Name $AppVmConfig.Name

$DbVmConfig = New-AzVMConfig -VMName 'DbVM' -VMSize 'Standard_B2s' | `
    Set-AzVMOperatingSystem -Linux -ComputerName 'Db-Vm' -Credential $VmCred | `
    Set-AzVMSourceImage -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '18.04-LTS' -Version latest | `
    Add-AzVMNetworkInterface -Id $DbVmNic.Id

$DbVm = New-AzVM -ResourceGroupName $RgName -Location $Region -VM $DbVmConfig
Start-AzVM -ResourceGroupName $RGName -Name $DbVmConfig.Name

#as admin
#Enable-PSRemoting -force

#Add app vm ip tp trusted hosts, allow ps session
$AppVmPublicIP = Get-AzPublicIpAddress -ResourceGroupName $RGName -Name 'App-PublicIP'
# $DbVmPublicIP = Get-AzPublicIpAddress -ResourceGroupName $RGName -Name 'DB-PublicIP'
#as admin
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $AppVmPublicIP.IpAddress -Force
# Set-Item WSMan:\localhost\Client\TrustedHosts -Value '104.211.38.2' -Force
# get-Item WSMan:\localhost\Client\TrustedHosts
# Invoke-Command {"& winrm set winrm/config/client @{TrustedHosts=$AppVmPublicIP.IpAddress}"}

# Invoke-Command -Command {".\PsExec.exe \\52.142.47.107 winrm quickconfig -force"} -verbose
Invoke-Expression -Command '.\PsExec.exe -i "\\$($AppVmPublicIP.IpAddress)" -u "$($AppVmPublicIP.IpAddress)\$($VmCred.UserName)" -p "$($VmCred.GetNetworkCredential().Password)" netsh advfirewall firewall add rule name="Open Port 5985" dir=in action=allow protocol=TCP localport=5985'
# .\PsExec.exe \\$($AppVmPublicIP.IpAddress) -u 'eduardgu' -p 'K8a54dqm014f!' netsh advfirewall firewall add rule name='Open Port 5985' dir=in action=allow protocol=TCP localport=5985
$AppScriptPath = ".\PublishNodeApp_V2.ps1"
# $AppScriptPath = "E:\source\repos\DevOps\Week 3\PublishNodeApp_V2.ps1"
# $AppScriptPath = "E:\source\repos\DevOps\Week 3\a.ps1"
#### Invoke-AzVMRunCommand -ResourceGroupName $RGName -VMname $AppVmConfig.Name -ScriptPath $AppScriptPath -CommandId RunPowerShellScript -Verbose 
# Invoke-AzVMRunCommand -ResourceGroupName "Test" -VMname "AppVM" -ScriptPath $AppScriptPath -CommandId RunPowerShellScript -Verbose
$AppConfig = @{
    "DbIp" = "$($DbVmPrivateIPConfig.PrivateIpAddress)"
    "OktaUrl" = "https://dev-91725987.okta.com"
    "OktaId" = "0oac29sg1MnlaSgsu5d6"
    "OktaSec" = "tyM1Gtw1rGwXVscTZ1uTBjPj6ZzvazWVTehyuCex"

}
Invoke-Command -ComputerName $AppVmPublicIP.IpAddress -FilePath $AppScriptPath `
    -ArgumentList $AppVmPublicIP.IpAddress, $AppConfig.DbIp, $AppConfig.OktaUrl, $AppConfig.OktaId, $AppConfig.OktaSec `
    -Credential $VmCred

Invoke-Command -ComputerName $AppVmPublicIP.IpAddress `
    -ScriptBlock {$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")} `
    -Credential $VmCred


# Invoke-AzVMRunCommand -ResourceGroupName "Test" -VMname "AppVm" -ScriptPath $AppScriptPath -CommandId RunPowerShellScript -Verbose



# ALLOW SSH TO DB NEEDS IP - CHECK HOW TO BLOCK


#get dbvm ip

# check app is accesible, db is private
# allow access todb from app only (hostname:port)

# run scripts on machine
# check if db need another storage
# add log
# add certificate to pssesion 
