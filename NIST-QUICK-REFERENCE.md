# NIST 800-53 Empty Effects - Quick Reference Guide

## Summary Table

| Effect | Count | Strategy | Notes |
|--------|-------|----------|-------|
| **Audit** | 10 | Use "Audit" for both prod & nonprod | Encryption/compliance with Deny options |
| **AuditIfNotExists** | 103 | Use "AuditIfNotExists" for both | Audit-based compliance checks |
| **DeployIfNotExists** | 2 | Use "DeployIfNotExists" for both | Deploy Guest Configuration extensions |
| **Modify** | 2 | Use "Modify" for both | Add system-assigned managed identity |
| **TOTAL** | **117** | See details below | All require implementation |

---

## Category 1: AUDIT (10 Policies)

**Use Effect:** `Audit`

These are encryption and security configuration policies. The "Audit" effect monitors without blocking. All have default=Disabled and support Deny/Audit.

1. **Azure Cosmos DB accounts should use customer-managed keys to encrypt data at rest**
2. **Azure Machine Learning workspaces should be encrypted with a customer-managed key**
3. **Cognitive Services accounts should enable data encryption with a customer-managed key**
4. **Container registries should be encrypted with a customer-managed key**
5. **Key Vault keys should have an expiration date**
6. **Key Vault secrets should have an expiration date**
7. **SQL managed instances should use customer-managed keys to encrypt data at rest**
8. **SQL servers should use customer-managed keys to encrypt data at rest**
9. **Storage accounts should restrict network access**
10. **Storage accounts should use customer-managed key for encryption**

---

## Category 2: AUDITIFNOTEXISTS (103 Policies)

**Use Effect:** `AuditIfNotExists`

These are compliance verification policies that audit whether required resources/configurations exist. This is the largest category.

### Subcategories (for easier management):

#### A. App Service Policies (6 policies)
- App Configuration should use private link
- App Service apps should have Client Certificates (Incoming client certificates) enabled
- App Service apps should have remote debugging turned off
- App Service apps should have resource logs enabled
- App Service apps should not have CORS configured to allow every resource to access your apps
- App Service apps should require FTPS only
- App Service apps should use latest 'HTTP Version'
- App Service apps should use managed identity
- App Service apps should use the latest TLS version
- Function apps should have remote debugging turned off
- Function apps should not have CORS configured to allow every resource to access your apps
- Function apps should require FTPS only
- Function apps should use latest 'HTTP Version'
- Function apps should use managed identity
- Function apps should use the latest TLS version

#### B. Infrastructure & Security (40+ policies)
Azure Backup, Cache, Data Factory, Event Hub, Disk Access, Storage, SQL, and various security/monitoring policies

#### C. Guest Configuration (15+ policies)
- Audit Linux machines that allow remote connections from accounts without passwords
- Audit Linux machines that do not have the passwd file permissions set to 0644
- Audit Linux machines that have accounts without passwords
- Audit Windows machines that allow re-use of the passwords
- Audit Windows machines that do not have the maximum password age set
- Audit Windows machines that do not have the minimum password age set
- Audit Windows machines that do not have the password complexity setting enabled
- Audit Windows machines that do not restrict the minimum password length
- Audit Windows machines that do not store passwords using reversible encryption
- Authentication to Linux machines should require SSH keys
- Linux machines should meet requirements for the Azure compute security baseline

#### D. Security Center Monitoring (35+ policies)
- A maximum of 3 owners should be designated for your subscription
- A vulnerability assessment solution should be enabled on your virtual machines
- Accounts with owner permissions on Azure resources should be MFA enabled
- Accounts with read permissions on Azure resources should be MFA enabled
- Accounts with write permissions on Azure resources should be MFA enabled
- Adaptive application controls for defining safe applications should be enabled
- Adaptive network hardening recommendations should be applied
- All network ports should be restricted on network security groups
- Allowlist rules in your adaptive application control policy should be updated
- Auto provisioning of the Log Analytics agent should be enabled
- Azure DDoS Protection should be enabled
- Azure Defender for App Service should be enabled
- Azure Defender for Azure SQL Database servers should be enabled
- Azure Defender for Key Vault should be enabled
- Azure Defender for Resource Manager should be enabled
- Azure Defender for servers should be enabled
- Azure Defender for SQL servers on machines should be enabled
- Blocked accounts with owner permissions should be removed
- Blocked accounts with read and write permissions should be removed
- Email notification for high severity alerts should be enabled
- Email notification to subscription owner for high severity alerts should be enabled
- Endpoint protection solution should be installed on virtual machine scale sets
- Guest accounts with owner permissions should be removed
- Guest accounts with read permissions should be removed
- Guest accounts with write permissions should be removed
- Guest Configuration extension should be installed on your machines
- Internet-facing virtual machines should be protected with network security groups
- IP Forwarding on your virtual machine should be disabled
- Log Analytics agent should be installed on your virtual machine
- Log Analytics agent should be installed on your virtual machine scale sets
- Management ports of virtual machines should be protected with JIT access
- Management ports should be closed on your virtual machines
- Microsoft Defender for Containers should be enabled
- Monitor missing Endpoint Protection in Azure Security Center
- Non-internet-facing virtual machines should be protected with NSGs
- SQL databases should have vulnerability findings resolved
- SQL servers on machines should have vulnerability findings resolved
- Subnets should be associated with a Network Security Group
- Subscriptions should have a contact email address for security issues
- System updates on virtual machine scale sets should be installed
- System updates should be installed on your machines
- There should be more than one owner assigned to your subscription
- Virtual machines should encrypt temp disks, caches, and data flows
- Virtual machines' Guest Configuration extension should be deployed with system-assigned MI
- Vulnerabilities in container security configurations should be remediated
- Vulnerabilities in security configuration on your machines should be remediated
- Vulnerabilities in security configuration on your VMSS should be remediated
- SQL servers should have an Azure AD administrator provisioned

#### E. Other Services (10+ policies)
- Azure Cache for Redis should use private link
- Azure Backup should be enabled for Virtual Machines
- Service Bus namespaces should use private link
- Azure File Sync should use private link
- Storage accounts should use private link
- Azure Data Factory should use private link
- Event Hub namespaces should use private link
- Azure Service Bus namespaces should use private link
- [Preview] policies for Arc machines, Kubernetes, Network, Monitoring

---

## Category 3: DEPLOYIFNOTEXISTS (2 Policies)

**Use Effect:** `DeployIfNotExists`

These policies automatically deploy required Guest Configuration extensions if they don't exist.

1. **Deploy the Linux Guest Configuration extension to enable Guest Configuration assignments on Linux VMs**
2. **Deploy the Windows Guest Configuration extension to enable Guest Configuration assignments on Windows VMs**

---

## Category 4: MODIFY (2 Policies)

**Use Effect:** `Modify`

These policies automatically add system-assigned managed identity when it's missing.

1. **Add system-assigned managed identity to enable Guest Configuration assignments on virtual machines with no identities**
2. **Add system-assigned managed identity to enable Guest Configuration assignments on VMs with a user-assigned identity**

---

## Implementation Steps

### Step 1: Backup Original File
```bash
cp Definitions/policyAssignments/nist-800-53-parameters.csv \
   Definitions/policyAssignments/nist-800-53-parameters.csv.backup
```

### Step 2: Update with Recommendations
```bash
python3 update-nist-effects.py \
  Definitions/policyAssignments/nist-800-53-parameters.csv \
  --backup \
  --prod same \
  --nonprod same
```

### Step 3: Verify
```bash
# Check that prodEffect and nonprodEffect are no longer empty
python3 -c "
import csv
with open('Definitions/policyAssignments/nist-800-53-parameters.csv', 'r') as f:
    reader = csv.DictReader(f)
    empty_count = 0
    for row in reader:
        if not row['prodEffect'].strip() or not row['nonprodEffect'].strip():
            empty_count += 1
    print(f'Empty policies remaining: {empty_count}')
"
```

### Step 4: Review in CSV Editor
1. Open with Excel or LibreOffice Calc
2. Filter by recommendation type
3. Review especially the 13 "Disabled" default policies
4. Adjust as needed for your environment

### Step 5: Commit Changes
```bash
git add Definitions/policyAssignments/nist-800-53-parameters.csv
git commit -m "Fill empty policy effects for NIST 800-53 compliance

- Added Audit effect to 10 encryption policies
- Added AuditIfNotExists effect to 103 compliance policies  
- Added DeployIfNotExists effect to 2 Guest Config extension policies
- Added Modify effect to 2 identity remediation policies
- Recommendations based on defaultEffect and allowedEffects"
```

---

## Environment-Specific Strategies

### For ALL Environments (Conservative)
```bash
# Prod: Recommended effect
# Nonprod: Disabled (test without impact)
python3 update-nist-effects.py csv_file --prod same --nonprod disabled
```

### For Unified Environments (Recommended)
```bash
# Same effect in prod and nonprod for consistency
python3 update-nist-effects.py csv_file --prod same --nonprod same
```

### For Phased Rollout
```bash
# Prod: Audit/AuditIfNotExists (observe-only)
# Nonprod: Disabled (test gradually)
# Then after validation, move prod to Deny/DeployIfNotExists/Modify
python3 update-nist-effects.py csv_file --prod same --nonprod disabled
```

---

## Validation Checklist

- [ ] All 117 policies now have prodEffect value
- [ ] All 117 policies now have nonprodEffect value
- [ ] No empty cells in prodEffect or nonprodEffect columns
- [ ] 10 policies have "Audit" effect
- [ ] 103 policies have "AuditIfNotExists" effect
- [ ] 2 policies have "DeployIfNotExists" effect
- [ ] 2 policies have "Modify" effect
- [ ] CSV is properly formatted and can be parsed
- [ ] Changes committed to version control
- [ ] Policy definitions reviewed by compliance team

---

## Special Notes

### Policies Marked "Disabled" by Default (Handle with Care)
These 13 policies have Microsoft's default as "Disabled". They may require configuration or have high operational impact:

- Azure Cosmos DB accounts should use customer-managed keys
- Azure Machine Learning workspaces should be encrypted
- Cognitive Services accounts should enable data encryption
- Key Vault keys should have an expiration date
- Key Vault secrets should have an expiration date
- MySQL servers should use customer-managed keys
- PostgreSQL servers should use customer-managed keys
- SQL managed instances should use customer-managed keys
- Storage accounts should restrict network access
- Subnets should be associated with a Network Security Group

**Recommendation:** Test these in nonprod first with "AuditIfNotExists" effect before enabling in production.

