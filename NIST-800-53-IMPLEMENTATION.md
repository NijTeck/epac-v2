# NIST 800-53 Empty Policy Effects - Implementation Guide

## Quick Start (2 Minutes)

1. **Review the analysis**: Open `nist-800-53-recommendations.csv`
2. **Run the update script**:
```bash
python3 update-nist-effects.py \
  Definitions/policyAssignments/nist-800-53-parameters.csv \
  --backup --prod same --nonprod same
```
3. **Commit the changes** and deploy

---

## Files Provided

### 1. nist-800-53-recommendations.csv
**Purpose:** Detailed breakdown of all 117 policies with recommendations
**Columns:**
- Policy ID and Display Name
- Category and Policy Type
- Current effects (empty)
- Allowed Effects (what's supported)
- Default Effect (Microsoft's recommendation)
- Recommended Effect (based on analysis)
- Has Parameters (Yes/No)
- Notes

**Use:** Review specific policies, validate recommendations, use for manual updates

---

### 2. NIST-800-53-ANALYSIS.md
**Purpose:** Comprehensive analysis with strategy recommendations
**Contains:**
- Executive summary
- Breakdown by effect type (Audit, AuditIfNotExists, DeployIfNotExists, Modify)
- Special attention items (13 policies with default=Disabled)
- Implementation strategies
- Next steps

**Use:** Understand the rationale and strategy for your environment

---

### 3. NIST-QUICK-REFERENCE.md
**Purpose:** Quick lookup guide with specific policy lists
**Contains:**
- Summary table
- All 10 Audit policies (with names)
- List of 103 AuditIfNotExists policies (with subcategories)
- 2 DeployIfNotExists policies
- 2 Modify policies
- Implementation steps
- Environment-specific strategies
- Validation checklist

**Use:** Find specific policies, implement changes, validate results

---

### 4. update-nist-effects.py
**Purpose:** Automated script to update the CSV with recommendations
**Features:**
- Intelligent effect selection based on allowed effects
- Backup original file
- Support for different strategies (prod vs nonprod)
- CSV validation
- Error handling

**Usage:**
```bash
# Basic usage (same effect for prod and nonprod)
python3 update-nist-effects.py csv_file.csv --backup --prod same --nonprod same

# Conservative approach (nonprod=Disabled)
python3 update-nist-effects.py csv_file.csv --backup --prod same --nonprod disabled

# Show help
python3 update-nist-effects.py --help
```

---

## Implementation Workflow

### Step 1: Choose Your Strategy

**Option A: Conservative (Safe)**
- Production: Use recommended effect (Audit/AuditIfNotExists)
- Non-Production: Disabled (test without impact)
```bash
python3 update-nist-effects.py csv_file --prod same --nonprod disabled
```

**Option B: Unified (Recommended)**
- Production & Non-Production: Same recommended effect
- Tests policies before production with full impact
```bash
python3 update-nist-effects.py csv_file --prod same --nonprod same
```

**Option C: Custom**
- Define effects manually
```bash
# Then review nist-800-53-recommendations.csv and edit the CSV directly
```

---

### Step 2: Review Special Attention Items

The 13 policies with default="Disabled" may require special handling:

1. Azure Cosmos DB accounts should use customer-managed keys
2. Azure Machine Learning workspaces should be encrypted
3. Cognitive Services accounts should enable data encryption
4. Key Vault keys should have an expiration date
5. Key Vault secrets should have an expiration date
6. MySQL servers should use customer-managed keys
7. PostgreSQL servers should use customer-managed keys
8. SQL managed instances should use customer-managed keys
9. Storage accounts should restrict network access
10. Subnets should be associated with a Network Security Group

**Recommendation:** Test these in nonprod with Audit/AuditIfNotExists before production.

---

### Step 3: Execute the Update

```bash
# Create backup
cp Definitions/policyAssignments/nist-800-53-parameters.csv \
   Definitions/policyAssignments/nist-800-53-parameters.csv.backup

# Run update with your chosen strategy
python3 update-nist-effects.py \
  Definitions/policyAssignments/nist-800-53-parameters.csv \
  --backup \
  --prod same \
  --nonprod same

# Verify the output
echo "Output saved to: Definitions/policyAssignments/nist-800-53-parameters.updated.csv"
```

---

### Step 4: Verify Results

```bash
# Check counts
python3 -c "
import csv

with open('Definitions/policyAssignments/nist-800-53-parameters.updated.csv', 'r') as f:
    reader = csv.DictReader(f)
    
    audit = 0
    auditifnotexists = 0
    deployifnotexists = 0
    modify = 0
    empty = 0
    
    for row in reader:
        prod_effect = row['prodEffect'].strip()
        
        if not prod_effect:
            empty += 1
        elif 'Audit' == prod_effect:
            audit += 1
        elif 'AuditIfNotExists' == prod_effect:
            auditifnotexists += 1
        elif 'DeployIfNotExists' == prod_effect:
            deployifnotexists += 1
        elif 'Modify' == prod_effect:
            modify += 1
    
    print(f'Verification Results:')
    print(f'  Empty:              {empty}')
    print(f'  Audit:              {audit}')
    print(f'  AuditIfNotExists:   {auditifnotexists}')
    print(f'  DeployIfNotExists:  {deployifnotexists}')
    print(f'  Modify:             {modify}')
    print(f'  Total:              {audit + auditifnotexists + deployifnotexists + modify}')
"
```

**Expected output:**
```
Verification Results:
  Empty:              0
  Audit:              10
  AuditIfNotExists:   103
  DeployIfNotExists:  2
  Modify:             2
  Total:              117
```

---

### Step 5: Review & Approve

1. Open the updated CSV in Excel or your preferred editor
2. Spot-check policies from each category
3. Verify all effects are filled in
4. Review the 13 "Disabled default" policies specifically
5. Make any adjustments needed for your environment

---

### Step 6: Commit & Deploy

```bash
# Review changes
git diff Definitions/policyAssignments/nist-800-53-parameters.csv

# Stage and commit
git add Definitions/policyAssignments/nist-800-53-parameters.csv
git commit -m "Fill empty policy effects for NIST 800-53 compliance

- Added Audit effect to 10 encryption/compliance policies
- Added AuditIfNotExists effect to 103 audit policies
- Added DeployIfNotExists effect to 2 Guest Config extension deployment policies
- Added Modify effect to 2 identity remediation policies

All recommendations based on:
- defaultEffect (Microsoft recommendations)
- allowedEffects (what each policy supports)
- Azure Policy best practices

Resolves 117 empty prodEffect and nonprodEffect fields."

# Push to remote
git push origin [branch-name]
```

---

## Key Statistics

| Metric | Count |
|--------|-------|
| **Total Empty Policies** | 117 |
| Audit Effect | 10 |
| AuditIfNotExists Effect | 103 |
| DeployIfNotExists Effect | 2 |
| Modify Effect | 2 |
| With Parameters | 92 |
| With Overrides | 25 |
| Default = Disabled (careful!) | 13 |

---

## Breakdown by Effect Type

### Audit (10 policies)
Focus: Encryption and security configuration monitoring
- No blocking, just observation
- Support Deny/Audit/Disabled
- Includes CMK encryption, key expiration, access restrictions

### AuditIfNotExists (103 policies)
Focus: Compliance verification
- Checks whether required resources/configurations exist
- Covers security, monitoring, and best practices
- Largest category - most NIST 800-53 controls use this

### DeployIfNotExists (2 policies)
Focus: Automated deployment
- Deploys Guest Configuration extensions on VMs
- Ensures agents are present for compliance checking

### Modify (2 policies)
Focus: Automated remediation
- Adds system-assigned managed identity
- Enables Guest Configuration capabilities

---

## Troubleshooting

### Script won't run
```bash
# Check Python is installed
python3 --version

# Make script executable
chmod +x update-nist-effects.py

# Run with explicit path
/usr/bin/python3 update-nist-effects.py csv_file
```

### CSV format issues
```bash
# Verify CSV is valid
python3 -c "import csv; list(csv.DictReader(open('file.csv')))"

# Check for encoding issues
file -i nist-800-53-parameters.csv  # Should be UTF-8
```

### Need to rollback
```bash
# Restore from backup
cp nist-800-53-parameters.csv.backup nist-800-53-parameters.csv
```

---

## Next Steps After Implementation

1. Deploy to your Azure environment
2. Monitor policy assignment status
3. Review compliance reports
4. Adjust effects based on your findings (Audit -> Deny, etc.)
5. Document your NIST 800-53 policy configuration

---

## Questions or Issues?

1. **Which effect should I use?** See NIST-QUICK-REFERENCE.md
2. **What do these policies do?** See nist-800-53-recommendations.csv
3. **How does this help NIST compliance?** See NIST-800-53-ANALYSIS.md
4. **How do I implement this?** See this file (NIST-800-53-IMPLEMENTATION.md)

---

## Support Information

**Files in this package:**
- NIST-800-53-ANALYSIS.md - Strategic analysis
- NIST-QUICK-REFERENCE.md - Quick lookup guide
- NIST-800-53-IMPLEMENTATION.md - This file
- nist-800-53-recommendations.csv - Policy details
- update-nist-effects.py - Automation script

**Recommended reading order:**
1. NIST-800-53-IMPLEMENTATION.md (this file)
2. NIST-QUICK-REFERENCE.md (for specifics)
3. nist-800-53-recommendations.csv (to review policies)
4. NIST-800-53-ANALYSIS.md (for deep dive)

