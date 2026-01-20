const fs = require('fs');
const path = require('path');

function parseFilesColumn(screensFiles) {
  const files = [];
  
  if (!screensFiles || screensFiles === '-' || screensFiles.startsWith('Multiple')) {
    return files;
  }
  
  // Split by comma to handle multiple files
  const fileParts = screensFiles.split(',');
  let lastFilePath = null;
  
  for (const filePart of fileParts) {
    const trimmed = filePart.trim();
    if (!trimmed) continue;
    
    // Check if there's a line number
    if (trimmed.includes(':')) {
      const lastColonIndex = trimmed.lastIndexOf(':');
      lastFilePath = trimmed.substring(0, lastColonIndex).trim();
      const lineInfo = trimmed.substring(lastColonIndex + 1).trim();
      
      // Handle line ranges (e.g., "177-178")
      if (lineInfo.includes('-')) {
        const [start, end] = lineInfo.split('-').map(n => parseInt(n, 10));
        if (!isNaN(start) && !isNaN(end)) {
          const lines = [];
          for (let i = start; i <= end; i++) {
            lines.push(i);
          }
          files.push({ path: lastFilePath, lines });
        } else {
          files.push({ path: lastFilePath, lines: [] });
        }
      } else {
        // Single line number
        const lineNum = parseInt(lineInfo, 10);
        if (!isNaN(lineNum)) {
          files.push({ path: lastFilePath, lines: [lineNum] });
        } else {
          files.push({ path: lastFilePath, lines: [] });
        }
      }
    } else if (lastFilePath) {
      // This is a continuation - just line numbers for the previous file
      // Handle line ranges (e.g., "183-184")
      if (trimmed.includes('-')) {
        const [start, end] = trimmed.split('-').map(n => parseInt(n, 10));
        if (!isNaN(start) && !isNaN(end)) {
          // Find the existing file entry and add lines to it
          const existingFile = files.find(f => f.path === lastFilePath);
          if (existingFile) {
            for (let i = start; i <= end; i++) {
              if (!existingFile.lines.includes(i)) {
                existingFile.lines.push(i);
              }
            }
            existingFile.lines.sort((a, b) => a - b);
          } else {
            const lines = [];
            for (let i = start; i <= end; i++) {
              lines.push(i);
            }
            files.push({ path: lastFilePath, lines });
          }
        }
      } else {
        // Single line number
        const lineNum = parseInt(trimmed, 10);
        if (!isNaN(lineNum)) {
          const existingFile = files.find(f => f.path === lastFilePath);
          if (existingFile) {
            if (!existingFile.lines.includes(lineNum)) {
              existingFile.lines.push(lineNum);
              existingFile.lines.sort((a, b) => a - b);
            }
          } else {
            files.push({ path: lastFilePath, lines: [lineNum] });
          }
        }
      }
    } else {
      // No line number, just path (and no previous file)
      if (trimmed) {
        lastFilePath = trimmed;
        files.push({ path: trimmed, lines: [] });
      }
    }
  }
  
  return files;
}

function parseMarkdownToJson(markdownPath) {
  const content = fs.readFileSync(markdownPath, 'utf-8');
  const lines = content.split('\n');
  const icons = [];
  let currentGroup = null;
  let inTable = false;
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    
    // Check for feature group header
    if (line.startsWith('## ') && !line.startsWith('## Summary') && !line.startsWith('## High Priority')) {
      currentGroup = line.substring(3).trim();
      inTable = false;
      continue;
    }
    
    // Check for table header
    if (line.includes('| ID |')) {
      inTable = true;
      i += 1; // Skip separator line
      continue;
    }
    
    // Check if we're leaving the table (empty line or new section)
    if (inTable && (!line || line.startsWith('##'))) {
      inTable = false;
      if (line.startsWith('##')) {
        i--; // Re-process this line as a header
      }
      continue;
    }
    
    // Parse table row
    if (inTable && line.startsWith('|') && !line.startsWith('|---')) {
      const parts = line.split('|').slice(1, -1).map(p => p.trim());
      
      if (parts.length >= 7) {
        const iconId = parts[0];
        const iconType = parts[1];
        const currentIcon = parts[2];
        const assetPath = parts[3] === '-' ? '' : parts[3];
        const screensFiles = parts[4];
        const context = parts[5];
        const description = parts[6];
        
        const files = parseFilesColumn(screensFiles);
        
        icons.push({
          id: iconId,
          type: iconType,
          current: currentIcon,
          files: files,
          context: context,
          description: description,
          feature_group: currentGroup
        });
      }
    }
  }
  
  return icons;
}

// Main execution
const icons = parseMarkdownToJson('docs/ICON_INVENTORY.md');
fs.writeFileSync('docs/ICON_INVENTORY.json', JSON.stringify(icons, null, 2), 'utf-8');
console.log(`Successfully parsed ${icons.length} icons to docs/ICON_INVENTORY.json`);
