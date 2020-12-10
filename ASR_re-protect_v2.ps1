#Use the recovery protection container, new cache storage account in West US and the source region VM resource group
#Set Recovery services vault context
$sourceresourcegroupname="ASR"
$recoveryvaultname="recoveryvault"
$vault = Get-AzRecoveryServicesVault -Name $recoveryvaultname -ResourceGroupName $sourceresourcegroupname 
Set-AzRecoveryServicesAsrVaultContext -Vault $vault


#Create Protection container mapping (for fail back) between the Recovery and Primary Protection Containers with the Replication policy
$ReplicationPolicyName="policyname"
$ProtectionContainername="zone1"
$RecoveryProtectionContainername="zone2"
$fabric_zone="westeurope"

$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $fabric_zone
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $RecoveryProtectionContainername
$ProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $ProtectionContainername
$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name $ReplicationPolicyName

$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "Zone2toZone1" -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $ProtContainer

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State
$Zone2toZone1Mapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "Zone2toZone1"

#Re-protect the VM
$vmname="myvmname"
$CachestorageAccountname="cacheaccount99"

$ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $vmname -ProtectionContainer $ProtContainer
$CacheStorageAccount=Get-AzStorageAccount -Name $CachestorageAccountname -ResourceGroupName $sourceresourcegroupname

Update-AzRecoveryServicesAsrProtectionDirection `
    -ReplicationProtectedItem $ReplicationProtectedItem `
    -ProtectionContainerMapping $Zone2toZone1Mapping `
    -LogStorageAccountId $CacheStorageAccount.Id -RecoveryResourceGroupID $sourceresourcegroupname.Id
