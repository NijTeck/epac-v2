# Remaining role assignments for service principals
$assignments = @(
    # epac-dev-owner - Resource Policy Contributor
    @{
        RoleId = "36243c78-bf99-498c-9df9-86d9f8d28608"
        PrincipalId = "21899d89-cc98-4672-b403-e406f1633861"
        Scope = "/providers/Microsoft.Management/managementGroups/P4CX-dev"
    },
    # epac-dev-owner - RBAC Administrator
    @{
        RoleId = "f58310d9-a9f6-439a-9e8d-f62e7b41a168"
        PrincipalId = "21899d89-cc98-4672-b403-e406f1633861"
        Scope = "/providers/Microsoft.Management/managementGroups/P4CX-dev"
    },
    # tenant-plan - Reader
    @{
        RoleId = "acdd72a7-3385-48ef-bd42-f606fba81ae7"
        PrincipalId = "298e871c-a83f-4600-84c6-c49d7017e73f"
        Scope = "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"
    },
    # tenant-policy - Reader
    @{
        RoleId = "acdd72a7-3385-48ef-bd42-f606fba81ae7"
        PrincipalId = "43a2ae25-c97b-4920-a397-d756a4484cf9"
        Scope = "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"
    },
    # tenant-policy - Resource Policy Contributor
    @{
        RoleId = "36243c78-bf99-498c-9df9-86d9f8d28608"
        PrincipalId = "43a2ae25-c97b-4920-a397-d756a4484cf9"
        Scope = "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"
    },
    # tenant-roles - Reader
    @{
        RoleId = "acdd72a7-3385-48ef-bd42-f606fba81ae7"
        PrincipalId = "7ab09c1c-3a7a-4875-8da9-6bea4db40a7d"
        Scope = "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"
    },
    # tenant-roles - RBAC Administrator
    @{
        RoleId = "f58310d9-a9f6-439a-9e8d-f62e7b41a168"
        PrincipalId = "7ab09c1c-3a7a-4875-8da9-6bea4db40a7d"
        Scope = "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"
    }
)

foreach ($assignment in $assignments) {
    $guid = [guid]::NewGuid().ToString()
    $body = @{
        properties = @{
            roleDefinitionId = "/providers/Microsoft.Authorization/roleDefinitions/$($assignment.RoleId)"
            principalId = $assignment.PrincipalId
            principalType = "ServicePrincipal"
        }
    } | ConvertTo-Json -Compress

    $uri = "https://management.azure.com$($assignment.Scope)/providers/Microsoft.Authorization/roleAssignments/$($guid)?api-version=2022-04-01"

    Write-Host "Assigning role $($assignment.RoleId) to $($assignment.PrincipalId)..."
    az rest --method put --uri $uri --body $body 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed (may already exist)" -ForegroundColor Yellow
    }
}