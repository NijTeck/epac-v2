# Configure all GitHub environments to use a single service principal
# This ensures consistency across all EPAC deployments

$servicePrincipalAppId = "<YOUR_SERVICE_PRINCIPAL_APP_ID>"
$servicePrincipalObjectId = "<YOUR_SERVICE_PRINCIPAL_OBJECT_ID>"
$tenantId = "<YOUR_TENANT_ROOT_MG_ID>"
$repoOwner = "<YOUR_GITHUB_ORG>"
$repoName = "<YOUR_REPO_NAME>"

$environments = @(
    "EPAC-DEV",
    "TENANT-PLAN",
    "TENANT-DEPLOY-POLICY",
    "TENANT-DEPLOY-ROLES"
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Configuring Single Service Principal for All Environments" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "Service Principal: epac-dev-owner" -ForegroundColor Yellow
Write-Host "App (Client) ID: $servicePrincipalAppId" -ForegroundColor White
Write-Host "Object ID: $servicePrincipalObjectId" -ForegroundColor White
Write-Host "Tenant ID: $tenantId" -ForegroundColor White
Write-Host ""

Write-Host "This will update secrets in the following GitHub environments:" -ForegroundColor Yellow
foreach ($env in $environments) {
    Write-Host "  - $env" -ForegroundColor White
}
Write-Host ""

$confirm = Read-Host "Do you want to proceed? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Updating GitHub environment secrets..." -ForegroundColor Green
Write-Host ""

foreach ($env in $environments) {
    Write-Host "Configuring environment: $env" -ForegroundColor Yellow

    # Set AZURE_CLIENT_ID
    try {
        gh secret set AZURE_CLIENT_ID --env $env --body $servicePrincipalAppId --repo "$repoOwner/$repoName"
        Write-Host "  ✅ AZURE_CLIENT_ID updated" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Failed to update AZURE_CLIENT_ID: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Set AZURE_TENANT_ID
    try {
        gh secret set AZURE_TENANT_ID --env $env --body $tenantId --repo "$repoOwner/$repoName"
        Write-Host "  ✅ AZURE_TENANT_ID updated" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Failed to update AZURE_TENANT_ID: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Configuration Complete!" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "✅ All GitHub environments now use the same service principal" -ForegroundColor Green
Write-Host "✅ Service Principal: epac-dev-owner ($servicePrincipalAppId)" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Verify federated credentials are configured for this service principal" -ForegroundColor White
Write-Host "2. Ensure all required RBAC roles are assigned (already done)" -ForegroundColor White
Write-Host "3. Re-run the GitHub Actions workflow" -ForegroundColor White
Write-Host ""

# Display current federated credentials
Write-Host "Checking federated credentials..." -ForegroundColor Yellow
Write-Host ""

try {
    $fedCreds = az ad app federated-credential list --id $servicePrincipalAppId -o json | ConvertFrom-Json

    if ($fedCreds.Count -gt 0) {
        Write-Host "Current federated credentials for epac-dev-owner:" -ForegroundColor Green
        foreach ($cred in $fedCreds) {
            Write-Host "  - Name: $($cred.name)" -ForegroundColor White
            Write-Host "    Subject: $($cred.subject)" -ForegroundColor Gray
            Write-Host "    Issuer: $($cred.issuer)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "⚠️  WARNING: No federated credentials found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "You need to add federated credentials for GitHub Actions OIDC:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "For each environment, run:" -ForegroundColor White
        Write-Host ""
        Write-Host "az ad app federated-credential create --id $servicePrincipalAppId --parameters '{" -ForegroundColor Gray
        Write-Host '  "name": "github-epac-dev",' -ForegroundColor Gray
        Write-Host '  "issuer": "https://token.actions.githubusercontent.com",' -ForegroundColor Gray
        Write-Host "  `"subject`": `"repo:$repoOwner/$repoName`:environment:EPAC-DEV`"," -ForegroundColor Gray
        Write-Host '  "audiences": ["api://AzureADTokenExchange"]' -ForegroundColor Gray
        Write-Host "}'" -ForegroundColor Gray
        Write-Host ""
    }
} catch {
    Write-Host "⚠️  Could not check federated credentials: $($_.Exception.Message)" -ForegroundColor Yellow
}
