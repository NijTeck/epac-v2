# Helper script to find policies and their effect parameters
# This helps you identify which policies you can override in your assignment

param(
    [string]$SearchTerm = "",
    [string]$ControlFamily = "",
    [switch]$ShowAll
)

Write-Host "Loading NIST R5 policy set..." -ForegroundColor Cyan

# Load the local NIST R5 policy set
$policySetPath = "built-in-policies/policySetDefinitions/Regulatory Compliance/NIST_SP_800-53_R5.json"

if (-not (Test-Path $policySetPath)) {
    Write-Host "Error: NIST R5 policy set not found at $policySetPath" -ForegroundColor Red
    Write-Host "Trying to get from Azure instead..." -ForegroundColor Yellow
    
    # Try from Azure
    $policySetId = "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f"
    $policySet = Get-AzPolicySetDefinition -Id $policySetId -ErrorAction SilentlyContinue
    
    if (-not $policySet) {
        Write-Host "Error: Could not load NIST R5 policy set from Azure either" -ForegroundColor Red
        exit 1
    }
    
    $policyRefs = $policySet.Properties.PolicyDefinitions
} else {
    $policySet = Get-Content $policySetPath -Raw | ConvertFrom-Json
    $policyRefs = $policySet.properties.policyDefinitions
}

Write-Host "Found $($policyRefs.Count) policies in NIST R5" -ForegroundColor Green
Write-Host ""

# Filter by control family if specified
if ($ControlFamily) {
    $policyRefs = $policyRefs | Where-Object {
        $_.groupNames -match "NIST_SP_800-53_R5_$ControlFamily"
    }
    Write-Host "Filtered to $($policyRefs.Count) policies in control family: $ControlFamily" -ForegroundColor Cyan
    Write-Host ""
}

# Get policy details from Azure
$policiesWithEffects = @()
$count = 0

foreach ($policyRef in $policyRefs) {
    $count++
    if ($count % 50 -eq 0) {
        Write-Host "  Processed $count policies..." -ForegroundColor Gray
    }
    
    $policyId = $policyRef.policyDefinitionId -replace ".*/policyDefinitions/", ""
    
    try {
        $policy = Get-AzPolicyDefinition -Id $policyRef.policyDefinitionId -ErrorAction Stop
        
        # Check if policy has effect parameter
        if ($policy.Properties.Parameters -and $policy.Properties.Parameters.effect) {
            $effectParam = $policy.Properties.Parameters.effect
            $displayName = $policy.Properties.DisplayName
            
            # Filter by search term if specified
            if ($SearchTerm -and $displayName -notmatch $SearchTerm) {
                continue
            }
            
            $policiesWithEffects += [PSCustomObject]@{
                PolicyId = $policyId
                DisplayName = $displayName
                DefaultEffect = $effectParam.defaultValue
                AllowedEffects = ($effectParam.allowedValues -join ", ")
                ControlFamilies = ($policyRef.groupNames | Where-Object { $_ -match "NIST_SP_800-53_R5_([A-Z]+)" } | ForEach-Object { $_ -replace "NIST_SP_800-53_R5_", "" }) -join ", "
            }
        }
    }
    catch {
        # Skip policies that can't be retrieved
        continue
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Policies with Configurable Effects" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($policiesWithEffects.Count -eq 0) {
    Write-Host "No policies found matching your criteria" -ForegroundColor Yellow
} else {
    Write-Host "Found $($policiesWithEffects.Count) policies with configurable effects" -ForegroundColor Green
    Write-Host ""
    
    if ($ShowAll) {
        $policiesWithEffects | Format-Table -AutoSize -Wrap
    } else {
        # Show first 20
        $policiesWithEffects | Select-Object -First 20 | Format-Table -AutoSize -Wrap
        
        if ($policiesWithEffects.Count -gt 20) {
            Write-Host ""
            Write-Host "Showing first 20 of $($policiesWithEffects.Count) policies" -ForegroundColor Yellow
            Write-Host "Use -ShowAll to see all policies" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "How to Override Effects in Assignment" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Add to your assignment file parameters section:" -ForegroundColor White
    Write-Host ""
    Write-Host '  "parameters": {' -ForegroundColor Gray
    Write-Host '    // Override policy effects' -ForegroundColor Gray
    Write-Host '    "effect": "Deny",  // Changes ALL policies with effect parameter' -ForegroundColor Gray
    Write-Host '    ' -ForegroundColor Gray
    Write-Host '    // OR override specific policies:' -ForegroundColor Gray
    
    # Show example for first policy
    if ($policiesWithEffects.Count -gt 0) {
        $example = $policiesWithEffects[0]
        Write-Host "    // $($example.DisplayName)" -ForegroundColor Gray
        Write-Host "    // Allowed: $($example.AllowedEffects)" -ForegroundColor Gray
        Write-Host "    `"policyEffect_$($example.PolicyId)`": `"Deny`"" -ForegroundColor Gray
    }
    
    Write-Host '  }' -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
Write-Host "Examples:" -ForegroundColor Cyan
Write-Host "  .\Scripts\Get-PolicyEffectParameters.ps1 -SearchTerm 'Storage'" -ForegroundColor Gray
Write-Host "  .\Scripts\Get-PolicyEffectParameters.ps1 -ControlFamily 'AC'" -ForegroundColor Gray
Write-Host "  .\Scripts\Get-PolicyEffectParameters.ps1 -ShowAll" -ForegroundColor Gray
