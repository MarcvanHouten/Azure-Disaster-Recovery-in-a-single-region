#!/bin/bash
#Create Azure Site Recovery environment
resourcegroupname="ASR"
location="westeurope"
vnetname="myvnet"
addressspace="10.1.0.0/24"
subnetname="vmsubnet"
subnetprefix="10.1.0.0/28"
nicname="nic1"
pipname="pip1"
vmname="myname"
vmsize="Standard_D4s_v3"
sourceppg="sourceppg"
recoveryppg="recppg"

#Create resource group
az group create \
    -g $resourcegroupname \
    --location $location
    
#Create virtual network
az network vnet create \
    -g $resourcegroupname \
    --name $vnetname \
    --address-prefix $addressspace \
    --subnet-name $subnetname \
    --subnet-prefix $subnetprefix

#Create source proximity placement group
az ppg create \
    --resource-group $resourcegroupname \
    --name $sourceppg

#Create recovery proximity placement group
az ppg create \
    --resource-group $resourcegroupname \
    --name $recoveryppg

#Create PIP
az network public-ip create \
    --name $pipname \
    --resource-group $resourcegroupname \
    --sku Standard

#Create NIC
az network nic create \
    --resource-group $resourcegroupname \
    --name $nicname \
    --subnet $subnetname \
    --vnet-name $vnetname \
    --public-ip-address $pipname \
    --accelerated-networking true

#Create VM
az vm create \
  --resource-group $resourcegroupname \
  --name $vmname \
  --image RedHat:RHEL:7.7:7.7.2020051912 \
  --size $vmsize \
  --admin-username azureuser \
  --generate-ssh-keys \
  --nics $nicname \
  --zone 1 \
  --ppg $sourceppg 

 
  