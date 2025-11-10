# Comprehensive EPAC Service Principal Permission Diagnostics
# Checks all required permissions for EPAC deployment

$servicePrincipalObjectId = "<YOUR_SERVICE_PRINCIPAL_OBJECT_ID>"
$servicePrincipalAppId = "<YOUR_SERVICE_PRINCIPAL_APP_ID>"
$tenantRootMG = "<YOUR_TENANT_ROOT_MG_ID>"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "EPAC Service Principal Permission Diagnostics" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

Write-Host "Service Principal: epac-dev-owner" -ForegroundColor Yellow
Write-Host "Object ID: $servicePrincipalObjectId" -ForegroundColor Gray
Write-Host "App ID: $servicePrincipalAppId" -ForegroundColor Gray
Write-Host ""

# Check Azure RBAC roles
Write-Host "1. Checking Azure RBAC Roles..." -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

$scope = "/providers/Microsoft.Management/managementGroups/$tenantRootMG"
$roles = Get-AzRoleAssignment -ObjectId $servicePrincipalObjectId -Scope $scope

$requiredRoles = @("Reader", "Resource Policy Contributor", "Role Based Access Control Administrator")

foreach ($roleName in $requiredRoles) {
    $hasRole = $roles | Where-Object { $_.RoleDefinitionName -eq $roleName }
    if ($hasRole) {
        Write-Host "  ✅ $roleName" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $roleName - MISSING!" -ForegroundColor Red
    }
}
Write-Host ""

# Check subscription access
Write-Host "2. Checking Subscription Access..." -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

$subscriptions = @(
    @{Id="<YOUR_DEV_SUBSCRIPTION_ID>"; Name="policycorte-dev"},
    @{Id="<YOUR_PROD_SUBSCRIPTION_ID>"; Name="policycortex-prod"}
)

foreach ($sub in $subscriptions) {
    $subRoles = Get-AzRoleAssignment -ObjectId $servicePrincipalObjectId -Scope "/subscriptions/$($sub.Id)" -ErrorAction SilentlyContinue
    if ($subRoles) {
        Write-Host "  ✅ $($sub.Name): $($subRoles.RoleDefinitionName -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $($sub.Name): No direct assignments (should inherit from MG)" -ForegroundColor Yellow
    }
}
Write-Host ""

# Check Azure AD Directory Roles
Write-Host "3. Checking Azure AD Directory Roles..." -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

try {
    $directoryRoles = az rest --method GET --url "https://graph.microsoft.com/v1.0/servicePrincipals/$servicePrincipalObjectId/memberOf" --query "value[].displayName" -o json | ConvertFrom-Json

    if ($directoryRoles -and $directoryRoles.Count -gt 0) {
        foreach ($role in $directoryRoles) {
            Write-Host "  ✅ $role" -ForegroundColor Green
        }
    } else {
        Write-Host "  ⚠️  No directory roles assigned" -ForegroundColor Yellow
        Write-Host "     Note: Directory Reader may be needed for some Resource Graph queries" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ⚠️  Could not query directory roles: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# Check Microsoft Graph API Permissions
Write-Host "4. Checking Microsoft Graph API Permissions..." -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

try {
    $app = az ad app show --id $servicePrincipalAppId -o json | ConvertFrom-Json
    $graphPermissions = $app.requiredResourceAccess | Where-Object { $_.resourceAppId -eq "00000003-0000-0000-c000-000000000000" }

    if ($graphPermissions -and $graphPermissions.resourceAccess.Count -gt 0) {
        Write-Host "  ✅ Has $($graphPermissions.resourceAccess.Count) Graph API permission(s)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  No Microsoft Graph API permissions" -ForegroundColor Yellow
        Write-Host "     This is usually fine for EPAC, but may be needed for some queries" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ⚠️  Could not query Graph permissions: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# Test Resource Graph Query
Write-Host "5. Testing Resource Graph Query..." -ForegroundColor Green
Write-Host "-" * 40 -ForegroundColor Gray

try {
    $query = "resources | take 1"
    $result = Search-AzGraph -Query $query -ManagementGroup $tenantRootMG -ErrorAction Stop
    Write-Host "  ✅ Resource Graph query successful!" -ForegroundColor Green
    Write-Host "     Your current user can query Resource Graph" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Resource Graph query failed: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Recommendations" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "If the GitHub Actions workflow is still failing with AccessDenied:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Verify federated credentials are configured correctly in Azure AD" -ForegroundColor White
Write-Host "   - Go to Azure AD > App registrations > epac-dev-owner > Certificates & secrets" -ForegroundColor Gray
Write-Host "   - Check Federated credentials section" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Wait 30 minutes for full RBAC propagation" -ForegroundColor White
Write-Host "   - Azure Resource Graph can take longer to sync than regular RBAC" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Try adding Directory Reader role to service principal" -ForegroundColor White
Write-Host "   - Some Resource Graph queries require this Azure AD role" -ForegroundColor Gray
Write-Host "   - Run: az ad directory-role member add --role 'Directory Readers' --member-id $servicePrincipalObjectId" -ForegroundColor Gray
Write-Host ""
