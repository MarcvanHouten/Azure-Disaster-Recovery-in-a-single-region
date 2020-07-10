#API used: https://docs.microsoft.com/en-us/rest/api/site-recovery/replicationprotectioncontainers/switchprotection
#The failback is done based on the REST API because the powershell is missing this feature

#Get accesstoken from active Powershell session
$currentAzureContext = Get-AzContext

$azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
$token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId).AccessToken;

### Creating the request header.
$Header = @{"authorization" = "bearer $token"}
$Header['Content-Type'] = "application\json"


#Get the values for the url and body






$Url = "https://management.azure.com/Subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR/providers/Microsoft.RecoveryServices/vaults/recoveryvault/replicationFabrics/westeurope/replicationProtectionContainers/zone1/switchprotection?api-version=2018-07-10"
$body = @{
  "properties"= @{
    "replicationProtectedItemName"= "6e0be008-83f0-4b18-9431-726ff9bed369"
    "providerSpecificDetails" = @{
      "instanceType"= "A2A"
      "recoveryContainerId" =  "/Subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR/providers/Microsoft.RecoveryServices/vaults/recoveryvault/replicationFabrics/westeurope/replicationProtectionContainers/zone1"
     "recoveryAvailabilityZone" =  "1"
     "recoveryProximityPlacementGroupId" = "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR/providers/Microsoft.Compute/proximityPlacementGroups/sourceppg"
        "vmManagedDisks"= @(
		@{
          "diskId"= "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASRfailover/providers/Microsoft.Compute/disks/myname_OsDisk_1_cef57edf6ffc469aaf21ce464fca124f"
          "primaryStagingAzureStorageAccountId"= "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR/providers/Microsoft.Storage/storageAccounts/cacheaccount99"
          "recoveryResourceGroupId"= "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR"
          "recoveryReplicaDiskAccountType"= "Premium_LRS"
          "recoveryTargetDiskAccountType"= "Premium_LRS"
        }
		
		)
      "vmDisks"= @()
      "recoveryResourceGroupId"= "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR"
       "policyId" = "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR/providers/Microsoft.RecoveryServices/vaults/recoveryvault/replicationPolicies/policyname"
    }
  }
}

$BodyJson = ConvertTo-Json -Depth 8 -InputObject $body
$getpd = Invoke-WebRequest -Uri $Url -Headers $Header -Method 'POST' -ContentType "application/json" -Body $BodyJson  -UseBasicParsing