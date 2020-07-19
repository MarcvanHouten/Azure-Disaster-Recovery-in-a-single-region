$subscriptionId = "302ce6c4-c9fd-41b7-9b92-d41405a15eb6"
$rgName = "ASRfailover"
$vmName = "myname"


# Remove any locks t
$locks = Get-AzResourceLock -ResourceGroupName $rgName -ResourceName $vmName -ResourceType Microsoft.Compute/virtualMachines
if ($locks -ne $null -and $locks.Count -ge 0){
	$canDelete =  Read-Host 'The VM has locks that could prevent cleanup of Azure Site Recovery stale links left from previous protection. Do you want the locks deleted to ensure cleanup goes smoothly? Reply with Y/N.'
	
	if ($canDelete.ToLower() -eq "y"){
		Foreach ($lock in $locks) {
			$lockId = $lock.LockId
			Remove-AzResourceLock -LockId $lockId -Force
			Write-Host "Removed Lock $lockId for $vmName"
		}	
	}
}

$linksResourceId = 'https://management.azure.com/subscriptions/' + $subscriptionId  + '/providers/Microsoft.Resources/links'
$vmId = '/subscriptions/' + $subscriptionId + '/resourceGroups/' + $rgName + '/providers/Microsoft.Compute/virtualMachines/' + $vmName + '/'

Write-Host $("Deleting links for $vmId using resourceId: $linksResourceId")
 

$links = @(Get-AzResource -ResourceId $linksResourceId|  Where-Object {$_.Properties.sourceId -match $vmId -and $_.Properties.targetId.ToLower().Contains("microsoft.recoveryservices/vaults")})
Write-Host "Links to be deleted"
$links

#Delete all links which are of type 
Foreach ($link in $links)

{
 Write-Host $("Deleting link " + $link.Name)
 Remove-AzResource -ResourceId $link.ResourceId -Force
}


$links = @(Get-AzResource -ResourceId $linksResourceId|  Where-Object {$_.Properties.sourceId -match $vmId -and $_.Properties.targetId.ToLower().Contains("/protecteditemarmid/")})
Write-Host "Cross subscription Links to be deleted"
$links


#Delete all links which are of type 
Foreach ($link in $links)

{
 Write-Host $("Deleting link " + $link.Name)
 Remove-AzResource -ResourceId $link.ResourceId -Force
}
 
Write-Host $("Deleted all links ")