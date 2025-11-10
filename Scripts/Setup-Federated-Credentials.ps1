# Setup federated credentials for GitHub OIDC authentication
# This allows GitHub Actions to authenticate to Azure without secrets

$servicePrincipalAppId = "<YOUR_SERVICE_PRINCIPAL_APP_ID>"
$repoOwner = "<YOUR_GITHUB_ORG>"
$repoName = "<YOUR_REPO_NAME>"

$credentials = @(
    @{
        Name = "github-epac-dev"
        Environment = "EPAC-DEV"
    },
    @{
        Name = "github-tenant-plan"
        Environment = "TENANT-PLAN"
    },
    @{
        Name = "github-tenant-deploy-policy"
        Environment = "TENANT-DEPLOY-POLICY"
    },
    @{
        Name = "github-tenant-deploy-roles"
        Environment = "TENANT-DEPLOY-ROLES"
    }
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Setting up Federated Credentials for GitHub OIDC" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "Service Principal App ID: $servicePrincipalAppId" -ForegroundColor Yellow
Write-Host "Repository: $repoOwner/$repoName" -ForegroundColor Yellow
Write-Host ""

foreach ($cred in $credentials) {
    Write-Host "Creating credential: $($cred.Name)" -ForegroundColor Yellow
    Write-Host "  Environment: $($cred.Environment)" -ForegroundColor Gray

    $subject = "repo:$repoOwner/$repoName:environment:$($cred.Environment)"

    $body = @{
        name = $cred.Name
        issuer = "https://token.actions.githubusercontent.com"
        subject = $subject
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress

    try {
        az ad app federated-credential create `
            --id $servicePrincipalAppId `
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

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Verification" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$allCreds = az ad app federated-credential list --id $servicePrincipalAppId -o json | ConvertFrom-Json

Write-Host "All federated credentials for epac-dev-owner:" -ForegroundColor Green
Write-Host ""

foreach ($cred in $allCreds) {
    Write-Host "Name: $($cred.name)" -ForegroundColor White
    Write-Host "  Subject: $($cred.subject)" -ForegroundColor Gray
    Write-Host "  Issuer: $($cred.issuer)" -ForegroundColor Gray
    Write-Host "  Audiences: $($cred.audiences -join ', ')" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Setup complete! All GitHub environments are now configured to use OIDC." -ForegroundColor Green
