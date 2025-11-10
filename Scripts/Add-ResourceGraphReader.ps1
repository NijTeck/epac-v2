# Add Resource Graph Reader role to EPAC service principal
# This role is required for Azure Resource Graph queries

$servicePrincipalObjectId = "<YOUR_SERVICE_PRINCIPAL_OBJECT_ID>"
$managementGroupId = "<YOUR_TENANT_ROOT_MG_ID>"
$scope = "/providers/Microsoft.Management/managementGroups/$managementGroupId"

Write-Host "Adding Resource Graph Reader role..." -ForegroundColor Yellow
Write-Host "Service Principal: $servicePrincipalObjectId" -ForegroundColor Gray
Write-Host "Scope: $scope" -ForegroundColor Gray
Write-Host ""

try {
    # Resource Graph Reader role definition ID
    $roleDefinitionId = "e8d93021-d4a2-4e57-9e1e-a63c1e77a0b9"

    New-AzRoleAssignment `
        -ObjectId $servicePrincipalObjectId `
        -RoleDefinitionId $roleDefinitionId `
        -Scope $scope `
        -ErrorAction Stop | Out-Null

    Write-Host "✅ Successfully added Resource Graph Reader role" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already exists*") {
        Write-Host "✅ Resource Graph Reader role already assigned" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to add Resource Graph Reader role: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Verifying all role assignments..." -ForegroundColor Yellow
Get-AzRoleAssignment -ObjectId $servicePrincipalObjectId -Scope $scope |
    Select-Object RoleDefinitionName, Scope |
    Format-Table

Write-Host ""
Write-Host "IMPORTANT: Wait 5-10 minutes for Azure RBAC to propagate." -ForegroundColor Yellow
Write-Host ""
