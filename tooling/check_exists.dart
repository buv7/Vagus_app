import 'dart:io';

/// Development tool for Cursor to verify file existence before patching
///
/// Usage:
/// ```bash
/// dart tooling/check_exists.dart lib/screens/auth/login_screen.dart
/// ```
void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Error: No file path provided');
    print('Usage: dart tooling/check_exists.dart <file_path>');
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (file.existsSync()) {
    print('✅ File exists: $filePath');
    print('Last modified: ${file.lastModifiedSync()}');
    print('Size: ${file.lengthSync()} bytes');
    exit(0);
  } else {
    print('❌ File does not exist: $filePath');
    
    // Try to find similar files
    final directory = file.parent;
    if (directory.existsSync()) {
      print('\nFiles in ${directory.path}:');
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      
      if (files.isEmpty) {
        print('  (no Dart files found)');
      } else {
        for (final f in files) {
          print('  - ${f.path.split(Platform.pathSeparator).last}');
        }
      }
    } else {
      print('Directory does not exist: ${directory.path}');
    }
    
    exit(1);
  }
}

