#!/bin/bash

# Service principal object IDs
EPAC_DEV_SP="21899d89-cc98-4672-b403-e406f1633861"
TENANT_PLAN_SP="298e871c-a83f-4600-84c6-c49d7017e73f"
TENANT_POLICY_SP="43a2ae25-c97b-4920-a397-d756a4484cf9"
TENANT_ROLES_SP="7ab09c1c-3a7a-4875-8da9-6bea4db40a7d"

# Management Groups
DEV_MG="P4CX-dev"
PROD_MG="e1f3e196-aa55-4709-9c55-0e334c0b444f"

# Role Definition IDs
READER_ROLE="acdd72a7-3385-48ef-bd42-f606fba81ae7"
POLICY_CONTRIBUTOR_ROLE="36243c78-bf99-498c-9df9-86d9f8d28608"
RBAC_ADMIN_ROLE="f58310d9-a9f6-439a-9e8d-f62e7b41a168"

echo "Assigning roles for epac-dev-owner..."
# Reader role for epac-dev-owner
az rest --method put --uri "https://management.azure.com/providers/Microsoft.Management/managementGroups/$DEV_MG/providers/Microsoft.Authorization/roleAssignments/$(uuidgen -r)?api-version=2022-04-01" --body "{
  \"properties\": {
    \"roleDefinitionId\": \"/providers/Microsoft.Authorization/roleDefinitions/$READER_ROLE\",
    \"principalId\": \"$EPAC_DEV_SP\",
    \"principalType\": \"ServicePrincipal\"
  }
}" 2>/dev/null || echo "Reader role may already be assigned"

# Resource Policy Contributor for epac-dev-owner
az rest --method put --uri "https://management.azure.com/providers/Microsoft.Management/managementGroups/$DEV_MG/providers/Microsoft.Authorization/roleAssignments/$(uuidgen -r)?api-version=2022-04-01" --body "{
  \"properties\": {
    \"roleDefinitionId\": \"/providers/Microsoft.Authorization/roleDefinitions/$POLICY_CONTRIBUTOR_ROLE\",
    \"principalId\": \"$EPAC_DEV_SP\",
    \"principalType\": \"ServicePrincipal\"
  }
}" 2>/dev/null || echo "Policy Contributor role may already be assigned"

# RBAC Administrator for epac-dev-owner
az rest --method put --uri "https://management.azure.com/providers/Microsoft.Management/managementGroups/$DEV_MG/providers/Microsoft.Authorization/roleAssignments/$(uuidgen -r)?api-version=2022-04-01" --body "{
  \"properties\": {
    \"roleDefinitionId\": \"/providers/Microsoft.Authorization/roleDefinitions/$RBAC_ADMIN_ROLE\",
    \"principalId\": \"$EPAC_DEV_SP\",
    \"principalType\": \"ServicePrincipal\"
  }
}" 2>/dev/null || echo "RBAC Admin role may already be assigned"

echo "Assigning roles for tenant-plan..."
# Reader role for tenant-plan
az rest --method put --uri "https://management.azure.com/providers/Microsoft.Management/managementGroups/$PROD_MG/providers/Microsoft.Authorization/roleAssignments/$(uuidgen -r)?api-version=2022-04-01" --body "{
  \"properties\": {
    \"roleDefinitionId\": \"/providers/Microsoft.Authorization/roleDefinitions/$READER_ROLE\",
    \"principalId\": \"$TENANT_PLAN_SP\",
    \"principalType\": \"ServicePrincipal\"
  }
}" 2>/dev/null || echo "Reader role may already be assigned"

echo "Assigning roles for tenant-policy..."
# Reader role for tenant-policy
az rest --method put --uri "https://management.azure.com/providers/Microsoft.Management/managementGroups/$PROD_MG/providers/Microsoft.Authorization/roleAssignments/$(uuidgen -r)?api-version=2022-04-01" --body "{
  \"properties\": {
    \"roleDefinitionId\": \"/providers/Microsoft.Authorization/roleDefinitions/$READER_ROLE\",
    \"principalId\": \"$TENANT_POLICY_SP\",
    \"principalType\": \"ServicePrincipal\"
  }
}" 2>/dev/null || echo "Reader role may already be assigned"

# Resource Policy Contributor for tenant-policy
az rest --method put --uri "https://management.azure.com/providers/Microsoft.Management/managementGroups/$PROD_MG/providers/Microsoft.Authorization/roleAssignments/$(uuidgen -r)?api-version=2022-04-01" --body "{
  \"properties\": {
    \"roleDefinitionId\": \"/providers/Microsoft.Authorization/roleDefinitions/$POLICY_CONTRIBUTOR_ROLE\",
    \"principalId\": \"$TENANT_POLICY_SP\",
    \"principalType\": \"ServicePrincipal\"
  }
}" 2>/dev/null || echo "Policy Contributor role may already be assigned"

echo "Assigning roles for tenant-roles..."
# Reader role for tenant-roles
az rest --method put --uri "https://management.azure.com/providers/Microsoft.Management/managementGroups/$PROD_MG/providers/Microsoft.Authorization/roleAssignments/$(uuidgen -r)?api-version=2022-04-01" --body "{
  \"properties\": {
    \"roleDefinitionId\": \"/providers/Microsoft.Authorization/roleDefinitions/$READER_ROLE\",
    \"principalId\": \"$TENANT_ROLES_SP\",
    \"principalType\": \"ServicePrincipal\"
  }
}" 2>/dev/null || echo "Reader role may already be assigned"

# RBAC Administrator for tenant-roles
az rest --method put --uri "https://management.azure.com/providers/Microsoft.Management/managementGroups/$PROD_MG/providers/Microsoft.Authorization/roleAssignments/$(uuidgen -r)?api-version=2022-04-01" --body "{
  \"properties\": {
    \"roleDefinitionId\": \"/providers/Microsoft.Authorization/roleDefinitions/$RBAC_ADMIN_ROLE\",
    \"principalId\": \"$TENANT_ROLES_SP\",
    \"principalType\": \"ServicePrincipal\"
  }
}" 2>/dev/null || echo "RBAC Admin role may already be assigned"

echo "Role assignments complete!"