#!/usr/bin/env python3
"""Parse ICON_INVENTORY.md and convert to JSON format."""

import json
import re

def parse_files_column(screens_files):
    """Parse the Screens/Files column into structured file data."""
    files = []
    
    if not screens_files or screens_files == '-' or screens_files.startswith('Multiple'):
        return files
    
    # Split by comma to handle multiple files
    for file_part in screens_files.split(','):
        file_part = file_part.strip()
        
        if not file_part:
            continue
            
        # Check if there's a line number
        if ':' in file_part:
            # Split path and line info
            parts = file_part.rsplit(':', 1)
            path = parts[0].strip()
            line_info = parts[1].strip()
            
            # Handle line ranges (e.g., "177-178")
            if '-' in line_info:
                try:
                    start, end = map(int, line_info.split('-'))
                    files.append({
                        'path': path,
                        'lines': list(range(start, end + 1))
                    })
                except ValueError:
                    # If parsing fails, just add the path
                    files.append({'path': path, 'lines': []})
            else:
                # Single line number
                try:
                    line_num = int(line_info)
                    files.append({
                        'path': path,
                        'lines': [line_num]
                    })
                except ValueError:
                    # If parsing fails, just add the path
                    files.append({'path': path, 'lines': []})
        else:
            # No line number, just path
            if file_part.strip():
                files.append({
                    'path': file_part.strip(),
                    'lines': []
                })
    
    return files

def parse_markdown_to_json(markdown_path):
    """Parse the markdown inventory file and convert to JSON."""
    icons = []
    current_group = None
    in_table = False
    
    with open(markdown_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        # Check for feature group header
        if line.startswith('## ') and not line.startswith('## Summary') and not line.startswith('## High Priority'):
            current_group = line[3:].strip()
            in_table = False
            i += 1
            continue
        
        # Check for table header
        if '| ID |' in line:
            in_table = True
            i += 2  # Skip header and separator line
            continue
        
        # Check if we're leaving the table (empty line or new section)
        if in_table and (not line or line.startswith('##')):
            in_table = False
            if line.startswith('##'):
                i -= 1  # Re-process this line as a header
            i += 1
            continue
        
        # Parse table row
        if in_table and line.startswith('|') and not line.startswith('|---'):
            parts = [p.strip() for p in line.split('|')[1:-1]]
            
            if len(parts) >= 7:
                icon_id = parts[0]
                icon_type = parts[1]
                current_icon = parts[2]
                asset_path = parts[3] if parts[3] != '-' else ''
                screens_files = parts[4]
                context = parts[5]
                description = parts[6]
                
                files = parse_files_column(screens_files)
                
                icons.append({
                    'id': icon_id,
                    'type': icon_type,
                    'current': current_icon,
                    'files': files,
                    'context': context,
                    'description': description,
                    'feature_group': current_group
                })
        
        i += 1
    
    return icons

if __name__ == '__main__':
    icons = parse_markdown_to_json('docs/ICON_INVENTORY.md')
    
    with open('docs/ICON_INVENTORY.json', 'w', encoding='utf-8') as f:
        json.dump(icons, f, indent=2, ensure_ascii=False)
    
    print(f"Successfully parsed {len(icons)} icons to docs/ICON_INVENTORY.json")
