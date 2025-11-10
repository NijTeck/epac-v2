# Add Reader role to subscriptions for EPAC service principal
# This ensures the service principal can query resources across subscriptions

$servicePrincipalObjectId = "<YOUR_SERVICE_PRINCIPAL_OBJECT_ID>"
$subscriptions = @(
    "<YOUR_DEV_SUBSCRIPTION_ID>",  # policycorte-dev
    "<YOUR_PROD_SUBSCRIPTION_ID>"   # policycortex-prod
)

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Adding Reader role to subscriptions" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($subId in $subscriptions) {
    Write-Host "Processing subscription: $subId" -ForegroundColor Yellow

    $scope = "/subscriptions/$subId"

    # Check if role already exists
    $existingRole = Get-AzRoleAssignment -ObjectId $servicePrincipalObjectId -Scope $scope -RoleDefinitionName "Reader" -ErrorAction SilentlyContinue

    if ($existingRole) {
        Write-Host "  ✅ Reader role already assigned" -ForegroundColor Green
    } else {
        Write-Host "  Adding Reader role..." -ForegroundColor Gray
        try {
            New-AzRoleAssignment `
                -ObjectId $servicePrincipalObjectId `
                -RoleDefinitionName "Reader" `
                -Scope $scope `
                -ErrorAction Stop | Out-Null

            Write-Host "  ✅ Successfully added Reader role" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -like "*already exists*") {
                Write-Host "  ✅ Reader role already assigned" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    Write-Host ""
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Summary of all role assignments" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# Show all role assignments for the service principal
Get-AzRoleAssignment -ObjectId $servicePrincipalObjectId |
    Where-Object { $_.Scope -match "managementGroups|subscriptions" } |
    Select-Object RoleDefinitionName, Scope |
    Format-Table -AutoSize

Write-Host ""
Write-Host "IMPORTANT: Wait 5-10 minutes for Azure RBAC to propagate before re-running the pipeline." -ForegroundColor Yellow
Write-Host ""
