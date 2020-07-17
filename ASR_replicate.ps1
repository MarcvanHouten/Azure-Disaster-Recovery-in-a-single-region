#Set up disaster recovery for Azure virtual machines using Azure PowerShell

#Set variables
$sourceresourcegroupname="ASR"
$failoverresourcegroupname="ASRfailover"
$vmname="myname"
$location="west Europe"
$newppgname="recppg"
$vnetname="myvnet"

#Create failover resource group
New-AzResourceGroup -Name $failoverresourcegroupname -Location $location

#Get details of the virtual machine to be replicated
$VM = Get-AzVM -ResourceGroupName $sourceresourcegroupname -Name $vmname
Write-Output $VM

#Create a new Recovery services vault in the recovery region
$recoveryvaultname="recoveryvault"
$vault = New-AzRecoveryServicesVault -Name $recoveryvaultname -ResourceGroupName $sourceresourcegroupname -Location $location
Write-Output $vault

#Setting the vault context.
Set-AzRecoveryServicesAsrVaultContext -Vault $vault

#Create Primary ASR fabric
$fabric_zone="westeurope"
$TempASRJob = New-AzRecoveryServicesAsrFabric -Azure -Location  $location  -Name $fabric_zone

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        #If the job hasn't completed, sleep for 10 seconds before checking the job status again
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $fabric_zone

#Create a Protection container in the primary Azure region (within the Primary fabric)
$SourceProtectionContainername="zone1"
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $PrimaryFabric -Name $SourceProtectionContainername

# Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        #If the job hasn't completed, sleep for 10 seconds before checking the job status again
        Start-Sleep 5;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State
$SourceProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $SourceProtectionContainername

#Create a recovery container
$RecoveryProtectionContainername="zone2"
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainer -InputObject $PrimaryFabric -Name $RecoveryProtectionContainername

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        #If the job hasn't completed, sleep for 10 seconds before checking the job status again
        Start-Sleep 5;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $RecoveryProtectionContainername

#Create replication policy
$ReplicationPolicyName="policyname"
$TempASRJob = New-AzRecoveryServicesAsrPolicy -AzureToAzure -Name $ReplicationPolicyName -RecoveryPointRetentionInHours 24 -ApplicationConsistentSnapshotFrequencyInHours 4

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        start-sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}
#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name $ReplicationPolicyName

#Create Protection container mapping between the Primary and Recovery Protection Containers with the Replication policy
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "A2APrimaryToRecovery" -Policy $ReplicationPolicy -PrimaryProtectionContainer $SourceProtContainer -RecoveryProtectionContainer $RecoveryProtContainer

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        start-sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$PCMapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $SourceProtContainer -Name "A2APrimaryToRecovery"

#Create Cache storage account for replication logs in the primary region
$CachestorageAccountname="cacheaccount99"
$CacheStorageAccount = New-AzStorageAccount -Name $CachestorageAccountname -ResourceGroupName $sourceresourcegroupname -Location $location -SkuName Standard_LRS -Kind Storage

#$CacheStorageAccount=Get-AzStorageAccount -Name $CachestorageAccountname -ResourceGroupName $sourceresourcegroupname

#Get the resource group that the virtual machine must be created in when failed over.
$RecoveryRG = Get-AzResourceGroup -Name $failoverresourcegroupname -Location $location

#Specify replication properties for each disk of the VM that is to be replicated (create disk replication configuration)

#OsDisk
$OSdiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id
$RecoveryOSDiskAccountType = $vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
$RecoveryReplicaDiskAccountType = $vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType

$OSDiskReplicationConfig = New-AzRecoveryServicesAsrAzureToAzureDiskReplicationConfig -ManagedDisk -LogStorageAccountId $CacheStorageAccount.Id -DiskId $OSdiskId -RecoveryResourceGroupId  $RecoveryRG.ResourceId -RecoveryReplicaDiskAccountType  $RecoveryReplicaDiskAccountType -RecoveryTargetDiskAccountType $RecoveryOSDiskAccountType

#Create a list of disk replication configuration objects for the disks of the virtual machine that are to be replicated.
$diskconfigs = @()
$diskconfigs += $OSDiskReplicationConfig

$ppg = Get-AzProximityPlacementGroup -ResourceGroupName $sourceresourcegroupname -Name $newppgname

$DestinationRecoveryNetwork=Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $sourceresourcegroupname

#Start replication by creating replication protected item. Using a GUID for the name of the replication protected item to ensure uniqueness of name.
$TempASRJob = New-AzRecoveryServicesAsrReplicationProtectedItem -AzureToAzure -AzureVmId $VM.Id -Name (New-Guid).Guid -ProtectionContainerMapping $PCMapping -AzureToAzureDiskReplicationConfiguration $OSDiskReplicationConfig -RecoveryResourceGroupId $RecoveryRG.ResourceId -RecoveryAvailabilityZone "2" -RecoveryProximityPlacementGroupId $ppg.Id -RecoveryAzureNetworkId $DestinationRecoveryNetwork.Id 

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        start-sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State


