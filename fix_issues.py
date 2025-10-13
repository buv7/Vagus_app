#!/usr/bin/env python3
"""
Script to fix remaining Dart analysis issues
"""
import re
import subprocess
import sys

def get_issues():
    """Get all analysis issues"""
    result = subprocess.run(
        ['flutter', 'analyze'],
        cwd=r'C:\Users\alhas\StudioProjects\vagus_app',
        capture_output=True,
        text=True
    )
    return result.stderr

def fix_unused_fields():
    """Comment out unused fields"""
    issues = get_issues()

    # Find unused field issues
    pattern = r"The value of the field '([^']+)' isn't used - ([^:]+):(\d+):\d+ - unused_field"
    matches = re.findall(pattern, issues)

    print(f"Found {len(matches)} unused fields")

    for field_name, file_path, line_num in matches:
        if 'test' in file_path:
            continue  # Skip test files for now

        full_path = rf'C:\Users\alhas\StudioProjects\vagus_app\{file_path}'
        print(f"Commenting out {field_name} in {file_path}:{line_num}")

        try:
            with open(full_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()

            line_idx = int(line_num) - 1
            if line_idx < len(lines):
                # Comment out the line
                lines[line_idx] = '  // ' + lines[line_idx].lstrip()

            with open(full_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
        except Exception as e:
            print(f"  Error: {e}")

def fix_unnecessary_null_comparisons():
    """Fix unnecessary null comparisons"""
    issues = get_issues()

    # Find unnecessary null comparison issues
    pattern = r"The operand can't be 'null'.*- ([^:]+):(\d+):(\d+) - unnecessary_null_comparison"
    matches = re.findall(pattern, issues)

    print(f"\nFound {len(matches)} unnecessary null comparisons")

    for file_path, line_num, col_num in matches:
        if 'test' in file_path:
            continue

        full_path = rf'C:\Users\alhas\StudioProjects\vagus_app\{file_path}'
        print(f"Fixing null comparison in {file_path}:{line_num}:{col_num}")

        try:
            with open(full_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Remove != null and ! operators for non-nullable types
            # This is a simplistic fix - manual review recommended
            lines = content.split('\n')
            line_idx = int(line_num) - 1

            if line_idx < len(lines):
                line = lines[line_idx]
                # Try to fix common patterns
                line = re.sub(r'(\w+)\s*!=\s*null', r'\1', line)
                line = re.sub(r'\.toSet\(\)\!', r'.toSet()', line)
                line = re.sub(r'\.toList\(\)\!', r'.toList()', line)
                lines[line_idx] = line

            with open(full_path, 'w', encoding='utf-8', newline='\n') as f:
                f.write('\n'.join(lines))
        except Exception as e:
            print(f"  Error: {e}")

if __name__ == '__main__':
    print("Fixing Dart analysis issues...")
    fix_unused_fields()
    fix_unnecessary_null_comparisons()
    print("\nDone! Run 'flutter analyze' to see remaining issues.")
