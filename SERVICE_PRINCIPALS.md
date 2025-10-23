# Service Principal Setup Guide

This guide walks through creating and configuring service principals for NIST 800-53 EPAC deployment.

## Overview

You need service principals with federated credentials (OIDC) for GitHub Actions authentication. This is more secure than using client secrets.

### Service Principals Needed

| Service Principal | Purpose | Permissions Required |
|-------------------|---------|---------------------|
| epac-dev-owner | Dev environment deployment | Reader, Policy Contributor, RBAC Administrator (dev MG) |
| tenant-plan | Production plan generation | Reader (prod MG) |
| tenant-policy | Production policy deployment | Reader, Policy Contributor (prod MG) |
| tenant-roles | Production role deployment | Reader, RBAC Administrator (prod MG) |

**Note**: You can use fewer service principals if desired (e.g., one for dev, one for prod), but separate SPNs provide better security and audit trails.

## Prerequisites

- Azure AD admin permissions to create app registrations
- Owner or User Access Administrator role on target management groups
- Azure CLI or PowerShell installed

## Option 1: Automated Setup (PowerShell)

Use this script to create all service principals automatically.

### Setup Script

Save this as `Setup-ServicePrincipals.ps1`:

```powershell
#Requires -Modules Az.Accounts, Az.Resources

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$DevManagementGroupId,
    
    [Parameter(Mandatory=$true)]
    [string]$ProdManagementGroupId,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo
)

# Connect to Azure
Connect-AzAccount -Tenant $TenantId

# Function to create service principal with federated credential
function New-EpacServicePrincipal {
    param(
        [string]$DisplayName,
        [string]$EnvironmentName,
        [string]$ManagementGroupId,
        [string[]]$Roles
    )
    
    Write-Host "Creating service principal: $DisplayName" -ForegroundColor Cyan
    
    # Create app registration
    $app = New-AzADApplication -DisplayName $DisplayName
    
    # Create service principal
    $sp = New-AzADServicePrincipal -ApplicationId $app.AppId
    
    Write-Host "  App ID: $($app.AppId)" -ForegroundColor Green
    Write-Host "  Object ID: $($sp.Id)" -ForegroundColor Green
    
    # Add federated credential for GitHub Actions
    $federatedCred = @{
        name = "$EnvironmentName-github-oidc"
        issuer = "https://token.actions.githubusercontent.com"
        subject = "repo:$GitHubOrg/$GitHubRepo:environment:$EnvironmentName"
        audiences = @("api://AzureADTokenExchange")
    }
    
    New-AzADAppFederatedCredential -ApplicationObjectId $app.Id `
        -Name $federatedCred.name `
        -Issuer $federatedCred.issuer `
        -Subject $federatedCred.subject `
        -Audience $federatedCred.audiences
    
    Write-Host "  Federated credential created for environment: $EnvironmentName" -ForegroundColor Green
    
    # Assign roles
    $scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
    
    foreach ($role in $Roles) {
        Write-Host "  Assigning role: $role" -ForegroundColor Yellow
        
        $maxRetries = 5
        $retryCount = 0
        $assigned = $false
        
        while (-not $assigned -and $retryCount -lt $maxRetries) {
            try {
                New-AzRoleAssignment -ObjectId $sp.Id `
                    -RoleDefinitionName $role `
                    -Scope $scope `
                    -ErrorAction Stop
                
                $assigned = $true
                Write-Host "    ✓ Role assigned: $role" -ForegroundColor Green
            }
            catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Host "    Waiting for service principal propagation... (attempt $retryCount/$maxRetries)" -ForegroundColor Yellow
                    Start-Sleep -Seconds 10
                }
                else {
                    Write-Host "    ✗ Failed to assign role: $role" -ForegroundColor Red
                    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
    
    return @{
        DisplayName = $DisplayName
        AppId = $app.AppId
        ObjectId = $sp.Id
        Environment = $EnvironmentName
    }
}

# Create service principals
$servicePrincipals = @()

# 1. EPAC-DEV (all permissions for dev)
$servicePrincipals += New-EpacServicePrincipal `
    -DisplayName "epac-dev-owner" `
    -EnvironmentName "EPAC-DEV" `
    -ManagementGroupId $DevManagementGroupId `
    -Roles @("Reader", "Resource Policy Contributor", "Role Based Access Control Administrator")

# 2. TENANT-PLAN (read-only for prod planning)
$servicePrincipals += New-EpacServicePrincipal `
    -DisplayName "tenant-plan" `
    -EnvironmentName "TENANT-PLAN" `
    -ManagementGroupId $ProdManagementGroupId `
    -Roles @("Reader")

# 3. TENANT-DEPLOY-POLICY (policy deployment for prod)
$servicePrincipals += New-EpacServicePrincipal `
    -DisplayName "tenant-policy" `
    -EnvironmentName "TENANT-DEPLOY-POLICY" `
    -ManagementGroupId $ProdManagementGroupId `
    -Roles @("Reader", "Resource Policy Contributor")

# 4. TENANT-DEPLOY-ROLES (role deployment for prod)
$servicePrincipals += New-EpacServicePrincipal `
    -DisplayName "tenant-roles" `
    -EnvironmentName "TENANT-DEPLOY-ROLES" `
    -ManagementGroupId $ProdManagementGroupId `
    -Roles @("Reader", "Role Based Access Control Administrator")

# Output summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Service Principals Created Successfully" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

foreach ($sp in $servicePrincipals) {
    Write-Host "Environment: $($sp.Environment)" -ForegroundColor Yellow
    Write-Host "  Display Name: $($sp.DisplayName)"
    Write-Host "  App ID (AZURE_CLIENT_ID): $($sp.AppId)" -ForegroundColor Green
    Write-Host "  Object ID: $($sp.ObjectId)"
    Write-Host ""
}

Write-Host "Tenant ID (AZURE_TENANT_ID): $TenantId" -ForegroundColor Green
Write-Host "`nAdd these values as secrets in your GitHub environments." -ForegroundColor Cyan
```

### Run the Script

```powershell
.\Setup-ServicePrincipals.ps1 `
    -TenantId "<YOUR-TENANT-ID>" `
    -DevManagementGroupId "<YOUR-DEV-MG>" `
    -ProdManagementGroupId "<YOUR-PROD-MG>" `
    -GitHubOrg "<YOUR-GITHUB-ORG>" `
    -GitHubRepo "<YOUR-REPO-NAME>"
```

### Save the Output

Copy the App IDs and Tenant ID from the output. You'll need these for GitHub environment secrets.

## Option 2: Manual Setup (Azure Portal)

### Step 1: Create App Registration

For each service principal:

1. Navigate to **Azure Portal** > **Azure Active Directory** > **App registrations**
2. Click **New registration**
3. Configure:
   - **Name**: `epac-dev-owner` (or appropriate name)
   - **Supported account types**: Accounts in this organizational directory only
   - **Redirect URI**: Leave blank
4. Click **Register**
5. **Copy the Application (client) ID** - you'll need this for GitHub secrets

### Step 2: Create Federated Credential

For each app registration:

1. Navigate to **Certificates & secrets**
2. Click **Federated credentials** tab
3. Click **Add credential**
4. Select **GitHub Actions deploying Azure resources**
5. Configure:
   - **Organization**: Your GitHub username or organization
   - **Repository**: Your repository name
   - **Entity type**: Environment
   - **Environment name**: Match GitHub environment name (e.g., `EPAC-DEV`)
   - **Name**: `github-oidc-EPAC-DEV` (or appropriate name)
6. Click **Add**

Repeat for each environment:
- `EPAC-DEV`
- `TENANT-PLAN`
- `TENANT-DEPLOY-POLICY`
- `TENANT-DEPLOY-ROLES`

### Step 3: Assign Permissions

For each service principal, assign roles at the management group scope:

#### EPAC-DEV Service Principal

1. Navigate to **Management groups**
2. Select your **dev management group**
3. Click **Access control (IAM)**
4. Click **Add** > **Add role assignment**
5. Assign these roles:
   - **Reader**
   - **Resource Policy Contributor**
   - **Role Based Access Control Administrator**
6. Select the service principal you created
7. Click **Save**

#### TENANT-PLAN Service Principal

1. Navigate to your **production management group**
2. Click **Access control (IAM)**
3. Assign role:
   - **Reader**

#### TENANT-DEPLOY-POLICY Service Principal

1. Navigate to your **production management group**
2. Click **Access control (IAM)**
3. Assign roles:
   - **Reader**
   - **Resource Policy Contributor**

#### TENANT-DEPLOY-ROLES Service Principal

1. Navigate to your **production management group**
2. Click **Access control (IAM)**
3. Assign roles:
   - **Reader**
   - **Role Based Access Control Administrator**

## Verify Setup

### Verify Federated Credentials

```powershell
# List app registrations
Get-AzADApplication | Where-Object { $_.DisplayName -like "epac-*" -or $_.DisplayName -like "tenant-*" }

# Check federated credentials for an app
$app = Get-AzADApplication -DisplayName "epac-dev-owner"
Get-AzADAppFederatedCredential -ApplicationObjectId $app.Id
```

### Verify Role Assignments

```powershell
# Get service principal
$sp = Get-AzADServicePrincipal -DisplayName "epac-dev-owner"

# List role assignments
Get-AzRoleAssignment -ObjectId $sp.Id | Select-Object RoleDefinitionName, Scope
```

## Add Secrets to GitHub

For each GitHub environment, add these secrets:

1. Navigate to your GitHub repository
2. Click **Settings** > **Environments**
3. Select environment (e.g., `EPAC-DEV`)
4. Click **Add secret**
5. Add:
   - **Name**: `AZURE_CLIENT_ID`
   - **Value**: Application (client) ID from app registration
6. Click **Add secret**
7. Add:
   - **Name**: `AZURE_TENANT_ID`
   - **Value**: Your Azure AD tenant ID

Repeat for all four environments.

## Testing Authentication

Test that GitHub Actions can authenticate:

1. Create a test workflow:

```yaml
name: Test Authentication

on: workflow_dispatch

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    environment: EPAC-DEV
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          enable-AzPSSession: true
          allow-no-subscriptions: true
      
      - name: Test Azure Access
        uses: azure/powershell@v2
        with:
          inlineScript: |
            Get-AzContext
            Get-AzManagementGroup
          azPSVersion: "latest"
```

2. Run the workflow manually
3. Verify it completes successfully

## Security Best Practices

### Principle of Least Privilege

- ✅ Use separate service principals for different environments
- ✅ Grant minimum required permissions
- ✅ Scope permissions to specific management groups (not subscription or tenant root)

### Credential Management

- ✅ Use federated credentials (OIDC) instead of client secrets
- ✅ No secrets stored in GitHub (only client ID and tenant ID)
- ✅ Credentials automatically rotated by Azure AD

### Monitoring and Auditing

- ✅ Enable Azure AD sign-in logs
- ✅ Monitor service principal activity
- ✅ Set up alerts for suspicious activity
- ✅ Review role assignments quarterly

### Credential Rotation

Federated credentials don't expire, but you should:

1. Review service principals annually
2. Remove unused service principals
3. Update federated credentials if repository changes
4. Audit role assignments regularly

## Troubleshooting

### Issue: "OIDC token validation failed"

**Possible Causes**:
1. Federated credential not configured correctly
2. GitHub environment name doesn't match
3. Repository name doesn't match

**Solution**:
1. Verify federated credential subject matches: `repo:ORG/REPO:environment:ENV_NAME`
2. Check environment name is exact match (case-sensitive)
3. Verify organization and repository names are correct

### Issue: "Insufficient permissions"

**Possible Causes**:
1. Role assignment not propagated yet
2. Wrong scope for role assignment
3. Missing required role

**Solution**:
1. Wait 5-10 minutes for role assignment propagation
2. Verify role is assigned at management group scope (not subscription)
3. Check all required roles are assigned

### Issue: "Service principal not found"

**Possible Causes**:
1. Service principal not created yet
2. Service principal deleted
3. Wrong tenant

**Solution**:
1. Verify service principal exists: `Get-AzADServicePrincipal -DisplayName "epac-dev-owner"`
2. Check you're in the correct tenant
3. Recreate service principal if needed

### Issue: "Cannot find management group"

**Possible Causes**:
1. Management group ID incorrect
2. Service principal doesn't have Reader permission
3. Management group doesn't exist

**Solution**:
1. Verify management group ID: `Get-AzManagementGroup`
2. Check Reader role is assigned
3. Verify management group exists in correct tenant

## Appendix: Required Permissions

### Reader Role

Allows reading Azure resources and policy state.

**Required for**: All service principals

**Permissions**:
- Read policy definitions
- Read policy assignments
- Read management groups
- Read resource compliance state

### Resource Policy Contributor Role

Allows managing Azure Policy resources.

**Required for**: epac-dev-owner, tenant-policy

**Permissions**:
- Create/update/delete policy definitions
- Create/update/delete policy set definitions
- Create/update/delete policy assignments
- Create/update/delete policy exemptions

### Role Based Access Control Administrator Role

Allows managing role assignments.

**Required for**: epac-dev-owner, tenant-roles

**Permissions**:
- Create/update/delete role assignments
- Read role definitions
- Assign roles to managed identities

**Note**: This is a privileged role. Use with caution and audit regularly.

## Alternative: Using Client Secrets (Not Recommended)

If you cannot use federated credentials, you can use client secrets:

1. Navigate to app registration > **Certificates & secrets**
2. Click **New client secret**
3. Set expiration (max 24 months)
4. Copy the secret value (only shown once)
5. Add to GitHub as secret: `AZURE_CLIENT_SECRET`
6. Update workflows to use client secret authentication

**Drawbacks**:
- Secrets expire and must be rotated
- Secrets can be leaked
- Less secure than OIDC

**Only use if OIDC is not available in your environment.**

## Support

For issues with service principal setup:

1. Review Azure AD documentation: https://learn.microsoft.com/en-us/azure/active-directory/
2. Review GitHub OIDC documentation: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure
3. Contact your Azure administrator
4. Open GitHub issue in this repository
