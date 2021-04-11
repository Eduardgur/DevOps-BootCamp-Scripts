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


# vNet and 2 subnests prive & publiv 
$AppSbCfg = New-AzVirtualNetworkSubnetConfig -Name 'App-Subnet' -AddressPrefix '192.168.0.0/24'
$DbSbCfg = New-AzVirtualNetworkSubnetConfig -Name 'Db-Subnet' -AddressPrefix '192.168.1.0/24'
$Vnet = New-AzVirtualNetwork -ResourceGroupName $RGName -Name 'TestVnet' -Location $Region `
    -Subnet $AppSbCfg, $DbSbCfg -AddressPrefix '192.168.0.0/16'


# Nsg rule allow HTTP from internet to all
$NsgRuleHttp = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-All' -Description 'Allow HTTP' `
    -Access Allow -Protocol Tcp -DestinationPortRange 80 -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * 

# Nsg rule allow RDP from Internet to all
$NsgRuleRdp = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
    -Access Allow -Protocol Tcp -DestinationPortRange 3389 -Direction Inbound -Priority 200 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * 

# Nsg rule allow WinRm from internet to public subnet
$NsgRuleWinRM = New-AzNetworkSecurityRuleConfig -Name 'Allow-WinRm-App' -Description 'Allow WinRM' `
    -Access Allow -Protocol Tcp -DestinationPortRange 5985 -Direction Inbound -Priority 1000 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix '192.168.0.0/24' 

# Nsg rule allow SMB from internet to public subnet
$NsgRuleSMB = New-AzNetworkSecurityRuleConfig -Name 'Allow-SMB-APP' -Description 'Allow SMB' `
        -Access Allow -Protocol Tcp -DestinationPortRange 445 -Direction Inbound -Priority 1001 `
    -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix '192.168.0.0/24' 

# Nsg rule allow SSH from public subnet to private subnet
$NsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name 'Allow-SSH-DB' -Description 'Allow WinRM' `
    -Access Allow -Protocol Tcp -DestinationPortRange 22 -Direction Inbound -Priority 1002 `
    -SourceAddressPrefix '192.168.0.0/24' -SourcePortRange * -DestinationAddressPrefix '192.168.1.0/24' 

# Nsg rule allow Postgres from public subnet to private subnet
$NsgRuleDB = New-AzNetworkSecurityRuleConfig -Name 'Allow-App2Db-HTTP' -Description "Allow App2Db" `
    -Access Allow -Protocol Tcp -DestinationPortRange 5432 -Direction Inbound -Priority 100 `
    -SourceAddressPrefix '192.168.0.0/24' -SourcePortRange * -DestinationAddressPrefix '192.168.1.0/24'  




# Public subnet NSG
$AppNsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $Region `
    -Name 'App-Nsg' -SecurityRules $NsgRuleHttp, $NsgRuleRdp, $NsgRuleWinRM, $NsgRuleSMB
# Associate the public NSG to the punlic subnet.
Set-AzVirtualNetworkSubnetConfig -Name 'App-Subnet' -VirtualNetwork $Vnet -NetworkSecurityGroup $AppNsg `
    -AddressPrefix '192.168.0.0/24' 

# Private subnet NSG
$DbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $Region `
    -Name "Db-Nsg" -SecurityRules $NsgRuleDB, $NsgRuleSSH
# Associate the private NSG to the private subnet
Set-AzVirtualNetworkSubnetConfig -Name 'Db-Subnet' -VirtualNetwork $Vnet -NetworkSecurityGroup $DbNsg `
    -AddressPrefix '192.168.0.0/24' 



# Public IP for AppVM
$AppVmPublicIP = New-AzPublicIpAddress -ResourceGroupName $RgName -Name 'App-PublicIP' -location $Region -AllocationMethod Dynamic
# NIC for AppVM
$AppVmNic = New-AzNetworkInterface -ResourceGroupName $RgName -Location $Region `
    -Name 'App-Nic' -PublicIpAddress $AppVmPublicIP -NetworkSecurityGroup $AppNsg -Subnet $Vnet.Subnets[0]


#Private Ip for DbVM
$DbVmPrivateIPConfig = New-AzNetworkInterfaceIpConfig -Name 'Db-PrivateIp' -PrivateIpAddress 192.168.1.4 -Subnet $Vnet.Subnets[1]
# NIC for DbVM
$DbVmNic = New-AzNetworkInterface -ResourceGroupName $RgName -Location $Region `
    -Name 'Db-Nic' -IpConfigurationName $DbVmPrivateIPConfig.Name -NetworkSecurityGroup $DbNsg -Subnet $Vnet.Subnets[1] 

# TODO: Check :
# $DiagSa = New-AzStorageAccount -ResourceGroupName $RGName -Name "diagbootstorageaccount" -Location $Region -SkuName Standard_LRS -Kind StorageV2
# Set-AzVMBootDiagnostic -ResourceGroupName $RgName -VM $AppVm -Enable -StorageAccountName "diagbootstorageaccount"

# App VM in the public subnet
$AppVmConfig = New-AzVMConfig -VMName 'AppVM' -VMSize 'Standard_B2s' | `
    Set-AzVMOperatingSystem -Windows -ComputerName 'App-Vm' -Credential $VmCred | `
    Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest | `
    Add-AzVMNetworkInterface -Id $AppVmNic.Id

$AppVm = New-AzVM -ResourceGroupName $RgName -Location $Region -VM $AppVmConfig 
Start-AzVM -ResourceGroupName $RGName -Name $AppVmConfig.Name

# Db VM in the private subnet
$DbVmConfig = New-AzVMConfig -VMName 'DbVM' -VMSize 'Standard_B2s' | `
    Set-AzVMOperatingSystem -Linux -ComputerName 'Db-Vm' -Credential $VmCred | `
    Set-AzVMSourceImage -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '18.04-LTS' -Version latest | `
    Add-AzVMNetworkInterface -Id $DbVmNic.Id

$DbVm = New-AzVM -ResourceGroupName $RgName -Location $Region -VM $DbVmConfig
Start-AzVM -ResourceGroupName $RGName -Name $DbVmConfig.Name

#Enable PS session (as admin)
Enable-PSRemoting -force

#Add app vm ip tp trusted hosts, allow ps session (as admin)
$AppVmPublicIP = Get-AzPublicIpAddress -ResourceGroupName $RGName -Name 'App-PublicIP'
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $AppVmPublicIP.IpAddress -Force

# Open WinRM port on App Vm
Invoke-Expression -Command '.\PsExec.exe -i "\\$($AppVmPublicIP.IpAddress)" -u "$($AppVmPublicIP.IpAddress)\$($VmCred.UserName)" -p "$($VmCred.GetNetworkCredential().Password)" netsh advfirewall firewall add rule name="Open Port 5985" dir=in action=allow protocol=TCP localport=5985'
$AppScriptPath = ".\PublishNodeApp_V2.ps1"

# Run Install Script on App VM
$AppConfig = @{
    "DbIp" = "$($DbVmPrivateIPConfig.PrivateIpAddress)"
    "OktaUrl" = "https://dev-91725987.okta.com"
    "OktaId" = "0oac29sg1MnlaSgsu5d6"
    "OktaSec" = "tyM1Gtw1rGwXVscTZ1uTBjPj6ZzvazWVTehyuCex"

}
Invoke-Command -ComputerName $AppVmPublicIP.IpAddress -FilePath $AppScriptPath `
    -ArgumentList $AppVmPublicIP.IpAddress, $AppConfig.DbIp, $AppConfig.OktaUrl, $AppConfig.OktaId, $AppConfig.OktaSec `
    -Credential $VmCred

# Refresh ENV params on App VM
Invoke-Command -ComputerName $AppVmPublicIP.IpAddress `
    -ScriptBlock {$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")} `
    -Credential $VmCred

<# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 Install DB first (from app srv - no internet connection)
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #> 