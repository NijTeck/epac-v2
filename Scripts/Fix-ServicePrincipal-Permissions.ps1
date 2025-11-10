# Fix Service Principal Permissions for EPAC Deployment
# This script adds the Reader role required for Azure Resource Graph queries

param(
    [Parameter(Mandatory=$true)]
    [string]$ServicePrincipalObjectId,

    [Parameter(Mandatory=$false)]
    [string]$ManagementGroupId = "<YOUR_TENANT_ROOT_MG_ID>"
)

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "EPAC Service Principal Permission Fix" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

$scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"

Write-Host "Checking current role assignments for Service Principal..." -ForegroundColor Yellow
$existingRoles = Get-AzRoleAssignment -ObjectId $ServicePrincipalObjectId -Scope $scope

Write-Host ""
Write-Host "Current Roles at scope $scope :" -ForegroundColor Green
$existingRoles | Select-Object RoleDefinitionName, Scope | Format-Table

# Required roles for EPAC
$requiredRoles = @(
    @{
        Name = "Reader"
        RoleDefinitionId = "acdd72a7-3385-48ef-bd42-f606fba81ae7"
        Description = "Required for Azure Resource Graph queries and reading resources"
    },
    @{
        Name = "Resource Policy Contributor"
        RoleDefinitionId = "36243c78-bf99-498c-9df9-86d9f8d28608"
        Description = "Required for managing policy definitions and assignments"
    },
    @{
        Name = "Role Based Access Control Administrator"
        RoleDefinitionId = "f58310d9-a9f6-439a-9e8d-f62e7b41a168"
        Description = "Required for assigning managed identity roles for DeployIfNotExists policies"
    }
)

Write-Host ""
Write-Host "Checking and adding required roles..." -ForegroundColor Yellow
Write-Host ""

foreach ($role in $requiredRoles) {
    $hasRole = $existingRoles | Where-Object { $_.RoleDefinitionName -eq $role.Name }

    if ($hasRole) {
        Write-Host "✅ $($role.Name) - Already assigned" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $($role.Name) - MISSING" -ForegroundColor Red
        Write-Host "   Adding $($role.Name)..." -ForegroundColor Yellow

        try {
            New-AzRoleAssignment `
                -ObjectId $ServicePrincipalObjectId `
                -RoleDefinitionId $role.RoleDefinitionId `
                -Scope $scope `
                -ErrorAction Stop | Out-Null

            Write-Host "   ✅ Successfully added $($role.Name)" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Failed to add $($role.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host "   Description: $($role.Description)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Permission check complete!" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Final role assignments:" -ForegroundColor Yellow
Get-AzRoleAssignment -ObjectId $ServicePrincipalObjectId -Scope $scope |
    Select-Object RoleDefinitionName, Scope |
    Format-Table

Write-Host ""
Write-Host "IMPORTANT: Wait 5-10 minutes for Azure RBAC to propagate before running deployment again." -ForegroundColor Yellow
Write-Host ""
