# NIST 800-53 Policy Definitions

This directory contains custom Azure Policy definitions organized by NIST SP 800-53 R5 control families.

## Structure

Policies are organized into folders by control family:
- **CM-ConfigurationManagement**: Configuration Management policies
- **SI-SystemAndInformationIntegrity**: System and Information Integrity policies

## Custom Policies

We maintain only **custom policy definitions** in this repository. Built-in Azure policies are referenced by ID in the policy set definitions.

### CM - Configuration Management (2 policies)
- `custom-cm-linux-stig-compliance.json` - Linux VM STIG compliance baseline
- `custom-cm-windows-stig-compliance.json` - Windows VM STIG compliance baseline

### SI - System and Information Integrity (3 policies)
- `custom-si-defender-plans-deployment.json` - Auto-deploy Defender for Cloud plans (excluding Servers)
- `custom-si-security-contacts.json` - Configure security contact email for alerts
- `custom-si-vulnerability-assessment.json` - Auto-deploy vulnerability assessment on VMs

## Built-in Policies

The comprehensive NIST 800-53 R5 policy set (`comprehensive-nist-800-53-r5.jsonc`) references:
- **698 built-in policies** from Microsoft's NIST SP 800-53 R5 initiative
- Organized across 20 control families (AC, AT, AU, CA, CM, CP, IA, IR, MA, MP, PE, PL, PM, PS, PT, RA, SA, SC, SI, SR)

Built-in policies are **not stored locally** - they are referenced by their Azure Policy ID and deployed directly from Azure.

## EPAC Deployment

During EPAC deployment:
1. Custom policies are deployed from these JSON files
2. Built-in policies are referenced by ID from Azure
3. The policy set combines both custom and built-in policies
4. Assignments apply the complete NIST 800-53 R5 compliance framework

## Adding New Custom Policies

To add a new custom policy:
1. Create a JSON file in the appropriate control family folder
2. Use naming convention: `custom-{family-code}-{description}.json`
3. Include full policy definition with name, properties, policyRule, etc.
4. Reference the policy in the policy set definition

## References

- [NIST SP 800-53 R5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [Azure Policy Built-in Definitions](https://github.com/Azure/azure-policy/tree/master/built-in-policies)
- [EPAC Documentation](https://azure.github.io/enterprise-azure-policy-as-code/)
