# Setup GitLab OIDC Integration for EPAC
# This script configures Azure federated credentials for GitLab CI/CD

param(
    [Parameter(Mandatory=$true)]
    [string]$GitLabProjectPath,  # Format: "groupname/projectname"

    [Parameter(Mandatory=$true)]
    [string]$ServicePrincipalAppId,

    [Parameter(Mandatory=$false)]
    [string]$TenantId = "<YOUR_TENANT_ID>",

    [Parameter(Mandatory=$false)]
    [string]$TenantRootMgId = "<YOUR_TENANT_ROOT_MG_ID>"
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "GitLab OIDC Setup for EPAC" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  GitLab Project: $GitLabProjectPath" -ForegroundColor White
Write-Host "  Service Principal: $ServicePrincipalAppId" -ForegroundColor White
Write-Host "  Tenant ID: $TenantId" -ForegroundColor White
Write-Host "  Management Group: $TenantRootMgId" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Continue with setup? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Setup cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Step 1: Creating Federated Credentials..." -ForegroundColor Green
Write-Host ""

# Define federated credentials
$credentials = @(
    @{
        Name = "gitlab-epac-dev"
        Subject = "project_path:${GitLabProjectPath}:ref_type:branch:ref:feature/*"
        Description = "GitLab OIDC for EPAC Dev environment (feature branches)"
    },
    @{
        Name = "gitlab-tenant-plan"
        Subject = "project_path:${GitLabProjectPath}:ref_type:branch:ref:main"
        Description = "GitLab OIDC for Tenant Plan environment"
    },
    @{
        Name = "gitlab-tenant-deploy-policy"
        Subject = "project_path:${GitLabProjectPath}:ref_type:branch:ref:main"
        Description = "GitLab OIDC for Tenant Deploy Policy environment"
    },
    @{
        Name = "gitlab-tenant-deploy-roles"
        Subject = "project_path:${GitLabProjectPath}:ref_type:branch:ref:main"
        Description = "GitLab OIDC for Tenant Deploy Roles environment"
    }
)

foreach ($cred in $credentials) {
    Write-Host "Creating: $($cred.Name)" -ForegroundColor Yellow
    Write-Host "  Subject: $($cred.Subject)" -ForegroundColor Gray

    $body = @{
        name = $cred.Name
        issuer = "https://gitlab.com"
        subject = $cred.Subject
        description = $cred.Description
        audiences = @("https://gitlab.com")
    } | ConvertTo-Json -Compress

    try {
        az ad app federated-credential create `
            --id $ServicePrincipalAppId `
            --parameters $body | Out-Null

        Write-Host "  ✅ Created successfully" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*ConflictingObjects*") {
            Write-Host "  ✅ Already exists" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

Write-Host ""
Write-Host "Step 2: Verifying RBAC Role Assignments..." -ForegroundColor Green
Write-Host ""

$spObjectId = az ad sp show --id $ServicePrincipalAppId --query "id" -o tsv
$scope = "/providers/Microsoft.Management/managementGroups/$TenantRootMgId"

$requiredRoles = @("Reader", "Resource Policy Contributor", "Role Based Access Control Administrator")
$missingRoles = @()

foreach ($roleName in $requiredRoles) {
    $hasRole = az role assignment list `
        --assignee $spObjectId `
        --scope $scope `
        --role $roleName `
        --query "[].roleDefinitionName" -o tsv

    if ($hasRole) {
        Write-Host "  ✅ $roleName" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $roleName - MISSING!" -ForegroundColor Red
        $missingRoles += $roleName
    }
}

if ($missingRoles.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  WARNING: Missing required roles!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run these commands to assign missing roles:" -ForegroundColor Yellow
    Write-Host ""
    foreach ($role in $missingRoles) {
        Write-Host "az role assignment create \\" -ForegroundColor Gray
        Write-Host "  --assignee $spObjectId \\" -ForegroundColor Gray
        Write-Host "  --role '$role' \\" -ForegroundColor Gray
        Write-Host "  --scope '$scope'" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host ""
Write-Host "Step 3: Verification Summary" -ForegroundColor Green
Write-Host ""

$allCreds = az ad app federated-credential list --id $ServicePrincipalAppId -o json | ConvertFrom-Json

Write-Host "All federated credentials for this service principal:" -ForegroundColor White
Write-Host ""

foreach ($cred in $allCreds) {
    if ($cred.issuer -eq "https://gitlab.com") {
        Write-Host "  ✅ $($cred.name)" -ForegroundColor Green
        Write-Host "     Subject: $($cred.subject)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Configure GitLab CI/CD Variables:" -ForegroundColor Yellow
Write-Host "   Go to: Settings → CI/CD → Variables" -ForegroundColor White
Write-Host ""
Write-Host "   Add these variables (mark as Protected and Masked):" -ForegroundColor White
Write-Host "   • AZURE_CLIENT_ID = $ServicePrincipalAppId" -ForegroundColor Gray
Write-Host "   • AZURE_TENANT_ID = $TenantId" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Create GitLab Environments:" -ForegroundColor Yellow
Write-Host "   Go to: Deployments → Environments" -ForegroundColor White
Write-Host ""
Write-Host "   Create these environments:" -ForegroundColor White
Write-Host "   • epac-dev" -ForegroundColor Gray
Write-Host "   • tenant-plan" -ForegroundColor Gray
Write-Host "   • tenant-deploy-policy (set as protected, require approval)" -ForegroundColor Gray
Write-Host "   • tenant-deploy-roles (set as protected, require approval)" -ForegroundColor Gray
Write-Host ""

Write-Host "3. Commit and push .gitlab-ci.yml to trigger pipeline" -ForegroundColor Yellow
Write-Host ""

Write-Host "4. Test the pipeline:" -ForegroundColor Yellow
Write-Host "   git checkout -b feature/test-pipeline" -ForegroundColor Gray
Write-Host "   git push origin feature/test-pipeline" -ForegroundColor Gray
Write-Host ""

Write-Host "For detailed instructions, see GITLAB-SETUP.md" -ForegroundColor White
Write-Host ""
