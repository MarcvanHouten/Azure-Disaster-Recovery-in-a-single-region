#FAILBACK
#Get recovery vault
$sourceresourcegroupname="ASR"

$recoveryvaultname="recoveryvault"
$vault = Get-AzRecoveryServicesVault -Name $recoveryvaultname -ResourceGroupName $sourceresourcegroupname

#Setting the vault context.
Set-AzRecoveryServicesAsrVaultContext -Vault $vault

#Get replication policy
$ReplicationPolicyName="policyname"
$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name $ReplicationPolicyName


$fabric_zone="westeurope"
$SourceProtectionContainername="zone1"
$RecoveryProtectionContainername="zone2"
$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $fabric_zone
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $RecoveryProtectionContainername
$SourceProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $SourceProtectionContainername

#Create Protection container mapping (for fail back) between the Recovery and Primary Protection Containers with the Replication policy
$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "A2ARecoveryToPrimary" -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $SourceProtContainer

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

$failbackmapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "A2ARecoveryToPrimary"


#Use the Same cache storage account 
$CachestorageAccountname="cacheaccount99"
$CacheStorageAccount = Get-AzStorageAccount -Name $CachestorageAccountname -ResourceGroupName $sourceresourcegroupname 


#Use the recovery protection container, new cache storage account in West US and the source region VM resource group
#Get protectedItem
$vmname="myname"
$sourceppg="sourceppg"

$ppg = Get-AzProximityPlacementGroup -ResourceGroupName $sourceresourcegroupname -Name $sourceppg


#Get the resource group that the virtual machine must be created in when failed over.
$RG = Get-AzResourceGroup -Name $sourceresourcegroupname -Location "west europe"

$ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $vmname -ProtectionContainer $SourceProtContainer


Update-AzRecoveryServicesAsrProtectionDirection -AzureToAzure -ReplicationProtectedItem $ReplicationProtectedItem -ProtectionContainerMapping $failbackmapping -LogStorageAccountId $CacheStorageAccount.Id -RecoveryResourceGroupID $RG.ResourceId -RecoveryProximityPlacementGroupId $ppg.Id 
Update-AzRecoveryServicesAsrProtectionDirection -AzureToAzure -ProtectionContainerMapping $failbackmapping -LogStorageAccountId $CacheStorageAccount.Id -ReplicationProtectedItem $ReplicationProtectedItem -RecoveryProximityPlacementGroupId $ppg.Id 



url="https://management.azure.com${subid}/providers/Microsoft.NetApp/netAppAccounts/${anfaccountname}/capacityPools/${source_poolname}/volumes/${new_volumename}?api-version=2019-11-01"
jsn='{"location":"'"$location"'","properties": { "creationToken": "'"$new_filepath"'","snapshotId" : "'"$snapshotid"'","subnetId":"'"$subnetid"'","usageThreshold":536870912000}}'
authorization_token=$(az account get-access-token --query "accessToken" -o tsv)

curl -H "Content-Type: application/json" -H "Authorization: Bearer ${authorization_token}" -X PUT $url -d "${jsn}" -v

