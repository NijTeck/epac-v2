#!/usr/bin/env python3
"""
Script to update NIST 800-53 parameters CSV with recommended effect values.
This script fills empty prodEffect and nonprodEffect fields with intelligent recommendations.
"""

import csv
import sys
from pathlib import Path

def get_recommendation(allowed_effects, default_effect):
    """
    Determine the recommended effect based on allowed effects and default.
    
    Args:
        allowed_effects (str): Comma-separated allowed effects
        default_effect (str): The default effect recommended by Microsoft
    
    Returns:
        str: Recommended effect for prodEffect/nonprodEffect
    """
    # If there's a good default and it's not "Disabled", use it
    if default_effect and default_effect != 'Disabled':
        return default_effect
    
    # For Disabled defaults, pick the best available option
    if 'AuditIfNotExists' in allowed_effects:
        return 'AuditIfNotExists'
    elif 'Audit' in allowed_effects:
        return 'Audit'
    elif 'Deny' in allowed_effects:
        return 'Deny'
    elif 'DeployIfNotExists' in allowed_effects:
        return 'DeployIfNotExists'
    elif 'Modify' in allowed_effects:
        return 'Modify'
    
    # Fallback (shouldn't happen)
    return 'Audit'

def update_csv(csv_file, output_file=None, prod_effect_strategy='same', nonprod_effect_strategy='same'):
    """
    Update CSV file with recommended effects.
    
    Args:
        csv_file (str): Path to input CSV file
        output_file (str): Path to output CSV file (defaults to input with .updated extension)
        prod_effect_strategy (str): 'same' = use recommendation for both, 'disabled' = use Disabled, etc.
        nonprod_effect_strategy (str): Same options as prod_effect_strategy
    """
    
    if not Path(csv_file).exists():
        print(f"Error: File {csv_file} not found")
        return False
    
    if output_file is None:
        output_file = csv_file.replace('.csv', '.updated.csv')
    
    updated_count = 0
    skipped_count = 0
    
    try:
        # Read the CSV
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            rows = list(reader)
        
        # Update rows
        for row in rows:
            prod_effect = row.get('prodEffect', '').strip()
            nonprod_effect = row.get('nonprodEffect', '').strip()
            
            # Only update if at least one effect is empty
            if prod_effect == '' or nonprod_effect == '':
                allowed_effects = row.get('allowedEffects', '').strip()
                default_effect = row.get('defaultEffect', '').strip()
                
                recommendation = get_recommendation(allowed_effects, default_effect)
                
                # Apply strategies
                if prod_effect == '':
                    row['prodEffect'] = recommendation if prod_effect_strategy == 'same' else prod_effect_strategy
                if nonprod_effect == '':
                    row['nonprodEffect'] = recommendation if nonprod_effect_strategy == 'same' else nonprod_effect_strategy
                
                updated_count += 1
            else:
                skipped_count += 1
        
        # Write the updated CSV
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
        
        print(f"Successfully updated {csv_file}")
        print(f"  Updated: {updated_count} policies")
        print(f"  Skipped: {skipped_count} (already had both effects)")
        print(f"  Output:  {output_file}")
        
        return True
    
    except Exception as e:
        print(f"Error processing CSV: {e}")
        return False

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Update NIST 800-53 parameters CSV with recommended effect values'
    )
    parser.add_argument('csv_file', help='Input CSV file path')
    parser.add_argument('--output', '-o', help='Output CSV file path (default: input.updated.csv)')
    parser.add_argument('--prod', default='same', 
                       help='Strategy for prodEffect: "same" (default), "disabled", or specific effect')
    parser.add_argument('--nonprod', default='same',
                       help='Strategy for nonprodEffect: "same" (default), "disabled", or specific effect')
    parser.add_argument('--backup', action='store_true', help='Create a backup of the original file')
    
    args = parser.parse_args()
    
    # Create backup if requested
    if args.backup:
        backup_file = args.csv_file + '.backup'
        try:
            import shutil
            shutil.copy(args.csv_file, backup_file)
            print(f"Backup created: {backup_file}")
        except Exception as e:
            print(f"Warning: Could not create backup: {e}")
    
    # Update the CSV
    success = update_csv(
        args.csv_file,
        output_file=args.output,
        prod_effect_strategy=args.prod,
        nonprod_effect_strategy=args.nonprod
    )
    
    sys.exit(0 if success else 1)
