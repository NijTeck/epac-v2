# Setup Service Principals for EPAC

$ErrorActionPreference = "Stop"

# Configuration
$TenantId = "e1f3e196-aa55-4709-9c55-0e334c0b444f"
$DevManagementGroupId = "P4CX-dev"
$ProdManagementGroupId = "e1f3e196-aa55-4709-9c55-0e334c0b444f"  # Tenant Root Group
$GitHubOrg = "NijTeck"
$GitHubRepo = "epac-v2"

# Service principals to create
$servicePrincipals = @(
    @{
        DisplayName = "epac-dev-owner"
        Environment = "EPAC-DEV"
        ManagementGroup = $DevManagementGroupId
        Roles = @("Reader", "Resource Policy Contributor", "Role Based Access Control Administrator")
    },
    @{
        DisplayName = "tenant-plan"
        Environment = "TENANT-PLAN"
        ManagementGroup = $ProdManagementGroupId
        Roles = @("Reader")
    },
    @{
        DisplayName = "tenant-policy"
        Environment = "TENANT-DEPLOY-POLICY"
        ManagementGroup = $ProdManagementGroupId
        Roles = @("Reader", "Resource Policy Contributor")
    },
    @{
        DisplayName = "tenant-roles"
        Environment = "TENANT-DEPLOY-ROLES"
        ManagementGroup = $ProdManagementGroupId
        Roles = @("Reader", "Role Based Access Control Administrator")
    }
)

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Cyan
Connect-AzAccount -Tenant $TenantId

# Store credentials for GitHub
$githubSecrets = @{}

foreach ($sp in $servicePrincipals) {
    Write-Host "`nCreating service principal: $($sp.DisplayName)" -ForegroundColor Cyan

    # Check if app already exists
    $existingApp = Get-AzADApplication -DisplayName $sp.DisplayName -ErrorAction SilentlyContinue

    if ($existingApp) {
        Write-Host "  App already exists, using existing app" -ForegroundColor Yellow
        $app = $existingApp
    } else {
        # Create new app registration
        $app = New-AzADApplication -DisplayName $sp.DisplayName
        Write-Host "  Created app registration" -ForegroundColor Green
    }

    # Check if service principal exists
    $existingSp = Get-AzADServicePrincipal -ApplicationId $app.AppId -ErrorAction SilentlyContinue

    if ($existingSp) {
        Write-Host "  Service principal already exists" -ForegroundColor Yellow
        $spn = $existingSp
    } else {
        # Create service principal
        $spn = New-AzADServicePrincipal -ApplicationId $app.AppId
        Write-Host "  Created service principal" -ForegroundColor Green
    }

    Write-Host "  App ID: $($app.AppId)" -ForegroundColor Green
    Write-Host "  Object ID: $($spn.Id)" -ForegroundColor Green

    # Add federated credential for GitHub Actions
    $federatedCredName = "$($sp.Environment)-github-oidc"

    # Check if federated credential already exists
    $existingCreds = Get-AzADAppFederatedCredential -ApplicationObjectId $app.Id
    $existingCred = $existingCreds | Where-Object { $_.Name -eq $federatedCredName }

    if ($existingCred) {
        Write-Host "  Federated credential already exists" -ForegroundColor Yellow
    } else {
        $federatedCred = @{
            Name = $federatedCredName
            Issuer = "https://token.actions.githubusercontent.com"
            Subject = "repo:$($GitHubOrg)/$($GitHubRepo):environment:$($sp.Environment)"
            Audiences = @("api://AzureADTokenExchange")
        }

        New-AzADAppFederatedCredential -ApplicationObjectId $app.Id `
            -Name $federatedCred.Name `
            -Issuer $federatedCred.Issuer `
            -Subject $federatedCred.Subject `
            -Audience $federatedCred.Audiences

        Write-Host "  Created federated credential for environment: $($sp.Environment)" -ForegroundColor Green
    }

    # Assign roles at management group scope
    $scope = "/providers/Microsoft.Management/managementGroups/$($sp.ManagementGroup)"

    foreach ($roleName in $sp.Roles) {
        Write-Host "  Checking role: $roleName" -ForegroundColor Yellow

        # Check if role assignment already exists
        $existingAssignment = Get-AzRoleAssignment -ObjectId $spn.Id -RoleDefinitionName $roleName -Scope $scope -ErrorAction SilentlyContinue

        if ($existingAssignment) {
            Write-Host "    Role already assigned: $roleName" -ForegroundColor Yellow
        } else {
            # Add retry logic for role assignments
            $maxRetries = 5
            $retryCount = 0
            $assigned = $false

            while (-not $assigned -and $retryCount -lt $maxRetries) {
                try {
                    New-AzRoleAssignment -ObjectId $spn.Id `
                        -RoleDefinitionName $roleName `
                        -Scope $scope `
                        -ErrorAction Stop | Out-Null

                    $assigned = $true
                    Write-Host "    ✓ Role assigned: $roleName" -ForegroundColor Green
                }
                catch {
                    $retryCount++
                    if ($retryCount -lt $maxRetries) {
                        Write-Host "    Waiting for service principal propagation... (attempt $retryCount/$maxRetries)" -ForegroundColor Yellow
                        Start-Sleep -Seconds 10
                    }
                    else {
                        Write-Host "    ✗ Failed to assign role: $roleName" -ForegroundColor Red
                        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host "    You may need to assign this role manually" -ForegroundColor Yellow
                    }
                }
            }
        }
    }

    # Store credentials for GitHub
    $githubSecrets[$sp.Environment] = @{
        AZURE_CLIENT_ID = $app.AppId
        AZURE_TENANT_ID = $TenantId
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Service Principals Created Successfully" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "GitHub Secrets for each environment:`n" -ForegroundColor Yellow

foreach ($env in $githubSecrets.Keys) {
    Write-Host "Environment: $env" -ForegroundColor Cyan
    Write-Host "  AZURE_CLIENT_ID: $($githubSecrets[$env].AZURE_CLIENT_ID)" -ForegroundColor Green
    Write-Host "  AZURE_TENANT_ID: $($githubSecrets[$env].AZURE_TENANT_ID)" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Save these values to configure GitHub environments!" -ForegroundColor Cyan

# Export to JSON file for reference
$githubSecrets | ConvertTo-Json -Depth 10 | Out-File "github-secrets.json"
Write-Host "Secrets also saved to github-secrets.json" -ForegroundColor Green