# Vagus App Archive

This directory contains archived files that are no longer actively used in the application.

## Directory Structure

### `/disabled/`
Contains files that were disabled during development but may contain useful code for future reference:
- `nutrition_state_manager.dart.disabled` - Old nutrition state management
- `sustainability_service.dart.disabled` - Sustainability tracking service
- `voice_interface_service.dart.disabled` - Voice interface implementation
- `restaurant_service.dart.disabled` - Restaurant integration service
- `role_manager.dart.disabled` - Role management system
- `offline_banner.dart.disabled` - Offline status banner widget
- `offline_operation_queue.dart.disabled` - Offline operation queue
- `safe_network_image.dart.disabled` - Safe network image widget
- `safe_database_service.dart.disabled` - Safe database operations

### `/backup/`
Contains backup files created during development:
- `nutrition_plan_builder.dart.backup` - Backup of nutrition plan builder
- `nutrition_ai_backup.dart` - Backup of nutrition AI service

### `/unused_cache/`
Contains cache-related services that are not currently imported or used:
- `cache_service.dart.old` - General cache service (stub implementation)
- `performance_service.dart.old` - Performance optimization service
- `ai_cache.dart.old` - AI-specific caching service

## Notes

- These files are preserved for potential future use or reference
- Files marked with `.old` suffix are confirmed unused in the current codebase
- Files with `.disabled` suffix were intentionally disabled during development
- Files with `.backup` suffix are backup copies of active files

## Cleanup Recommendations

Files in this archive can be safely deleted if:
1. The functionality is confirmed to be replaced by newer implementations
2. The code is no longer relevant to the current application architecture
3. Storage space is a concern

**Last Updated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
