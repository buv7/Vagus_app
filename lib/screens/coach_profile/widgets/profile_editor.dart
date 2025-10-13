import 'package:flutter/material.dart';
import '../../../models/coach_profile.dart';

/// ProfileEditor widget - provides edit mode overlay for coach profiles
/// Currently handled inline in other widgets, but this provides a dedicated editor interface
class ProfileEditor extends StatefulWidget {
  final CoachProfile? profile;
  final Function(Map<String, dynamic>)? onSave;
  final VoidCallback? onCancel;

  const ProfileEditor({
    super.key,
    this.profile,
    this.onSave,
    this.onCancel,
  });

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _editedData;

  @override
  void initState() {
    super.initState();
    _editedData = {};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Edit form fields would go here
            const Text('Profile editor functionality'),

            const Spacer(),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      widget.onSave?.call(_editedData);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
