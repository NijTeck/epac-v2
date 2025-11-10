# Add Directory Readers role to EPAC service principal
# This Azure AD role is required for some Resource Graph queries

$servicePrincipalObjectId = "<YOUR_SERVICE_PRINCIPAL_OBJECT_ID>"

Write-Host "Adding Directory Readers role to service principal..." -ForegroundColor Yellow
Write-Host ""

try {
    # Get the Directory Readers role
    $roleId = az rest --method GET `
        --url "https://graph.microsoft.com/v1.0/directoryRoles?`$filter=displayName eq 'Directory Readers'" `
        --query "value[0].id" -o tsv

    if (-not $roleId) {
        Write-Host "Activating Directory Readers role template..." -ForegroundColor Yellow
        # Directory Readers role template ID
        $templateId = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b"

        $roleId = az rest --method POST `
            --url "https://graph.microsoft.com/v1.0/directoryRoles" `
            --body "{`"roleTemplateId`": `"$templateId`"}" `
            --query "id" -o tsv
    }

    Write-Host "Directory Readers role ID: $roleId" -ForegroundColor Gray
    Write-Host ""

    # Add the service principal to the role
    az rest --method POST `
        --url "https://graph.microsoft.com/v1.0/directoryRoles/$roleId/members/`$ref" `
        --body "{`"@odata.id`": `"https://graph.microsoft.com/v1.0/directoryObjects/$servicePrincipalObjectId`"}"

    Write-Host "✅ Successfully added Directory Readers role" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: Wait 5-10 minutes for the role to propagate, then re-run the pipeline." -ForegroundColor Yellow

} catch {
    if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*already a member*") {
        Write-Host "✅ Directory Readers role already assigned" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to add Directory Readers role" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "You may need to use Azure Portal:" -ForegroundColor Yellow
        Write-Host "1. Go to Azure AD > Roles and administrators" -ForegroundColor White
        Write-Host "2. Search for 'Directory Readers'" -ForegroundColor White
        Write-Host "3. Click on the role, then 'Add assignments'" -ForegroundColor White
        Write-Host "4. Search for 'epac-dev-owner' and add it" -ForegroundColor White
    }
}
