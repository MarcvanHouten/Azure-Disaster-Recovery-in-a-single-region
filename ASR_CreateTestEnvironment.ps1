#Create Azure Site Recovery environment
$UserName="demouser"
$Password="Password@123" | ConvertTo-SecureString -Force -AsPlainText
$resourcegroupname="ASR"
$location="westeurope"
$vmname="myvmname"
$sourceppg="sourceppg"
$recoveryppg="recppg"
$NetworkName = "myvnet"
$NICName = "nic1"
$SubnetName = "vmsubnet"
$SubnetAddressPrefix = "10.1.0.0/28"
$VnetAddressPrefix = "10.1.0.0/24"
$vmsize="Standard_D4s_v3"

#Create resource group
New-AzResourceGroup -Name $resourcegroupname -Location $location

#Create source proximity placement group
$SourceProximityPlacementGroup = New-AzProximityPlacementGroup `
    -ResourceGroupName $resourcegroupname `
    -Name $sourceppg `
    -Location $location 

#Create recovery proximity placement group
New-AzProximityPlacementGroup `
    -ResourceGroupName $resourcegroupname `
    -Name $recoveryppg `
    -Location $location 

#Create Network Security rule configuration
$sshrule = New-AzNetworkSecurityRuleConfig `
    -Name "sshrule" `
    -Description "Allow SSH" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority "100" `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22

#Create network security group
$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Name "myNSG" `
    -SecurityRules $sshrule

#Create virtual network
$Subnet = New-AzVirtualNetworkSubnetConfig `
    -Name $SubnetName `
    -AddressPrefix $SubnetAddressPrefix `
    -NetworkSecurityGroup $nsg

$Vnet = New-AzVirtualNetwork `
    -Name $NetworkName `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -AddressPrefix $VnetAddressPrefix `
    -Subnet $Subnet

#Create PIP
$DNSNameLabel =  "pip" + (get-random) # mydnsname.westus.cloudapp.azure.com
$PublicIPAddressName = "MyPIP"
$PIP = New-AzPublicIpAddress `
    -Name $PublicIPAddressName `
    -DomainNameLabel $DNSNameLabel `
    -ResourceGroupName $ResourceGroupName `
    -AllocationMethod 'static' `
    -Location $Location `
    -sku 'Standard'

$NIC = New-AzNetworkInterface `
-Name $NICName `
-ResourceGroupName $ResourceGroupName `
-Location $Location `
-Subnet $vnet.Subnets[0] `
 -PublicIpAddress $PIP `
-PrivateIpAddress '10.1.0.4' `
-EnableAcceleratedNetworking 

#################

$Credential=New-Object PSCredential($UserName,$Password)

$VirtualMachine = New-AzVMConfig `
   -VMName $vmname `
   -VMSize $vmsize `
   -Zone "1" `
   -ProximityPlacementGroupId $SourceProximityPlacementGroup.id
  
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName 'vm1' -Credential $Credential 
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'RedHat' -Offer 'RHEL' -Skus '7.7' -version '7.7.2020051912' 

New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -OpenPorts 22 -Verbose

<#
Get-AzVMImageSku `
   -Location $Location `
   -PublisherName "RedHat" `
   -Offer "RHEL"
#>
