import 'package:flutter/material.dart';
import 'package:vagus_app/services/admin/admin_support_service.dart';



class AdminSlaPoliciesScreen extends StatefulWidget {
  const AdminSlaPoliciesScreen({super.key});

  @override
  State<AdminSlaPoliciesScreen> createState() => _AdminSlaPoliciesScreenState();
}

class _AdminSlaPoliciesScreenState extends State<AdminSlaPoliciesScreen> {
  final AdminSupportService _service = AdminSupportService.instance;
  final _formKey = GlobalKey<FormState>();
  
  List<SlaPolicyV7> _policies = [];
  bool _isLoading = true;
  bool _isCreating = false;
  SlaPolicyV7? _editingPolicy;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _responseTimeController = TextEditingController();
  final _resolutionTimeController = TextEditingController();
  String _selectedPriority = 'medium';
  bool _isActive = true;
  
  final List<String> _priorities = ['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _responseTimeController.dispose();
    _resolutionTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicies() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final policies = await _service.listPolicies();
      if (!mounted) return;
      
      setState(() {
        _policies = policies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  void _showPolicyForm({SlaPolicyV7? policy}) {
    _editingPolicy = policy;
    _isCreating = policy == null;
    
    if (policy != null) {
      _nameController.text = policy.name;
      _descriptionController.text = policy.description;
      _responseTimeController.text = policy.responseTime.inMinutes.toString();
      _resolutionTimeController.text = policy.resolutionTime.inMinutes.toString();
      _selectedPriority = policy.priority;
      _isActive = policy.isActive;
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _responseTimeController.clear();
      _resolutionTimeController.clear();
      _selectedPriority = 'medium';
      _isActive = true;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildPolicyForm(),
    );
  }

  Widget _buildPolicyForm() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isCreating ? 'Create SLA Policy' : 'Edit SLA Policy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Policy Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Policy Name',
                hintText: 'e.g., Standard Support, Premium Support',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Policy name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what this policy covers',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Priority
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority Level',
                border: OutlineInputBorder(),
              ),
              items: _priorities.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Response Time
            TextFormField(
              controller: _responseTimeController,
              decoration: const InputDecoration(
                labelText: 'Response Time (minutes)',
                hintText: 'e.g., 60 for 1 hour',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Response time is required';
                }
                final minutes = int.tryParse(value);
                if (minutes == null || minutes <= 0) {
                  return 'Please enter a valid number of minutes';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Resolution Time
            TextFormField(
              controller: _resolutionTimeController,
              decoration: const InputDecoration(
                labelText: 'Resolution Time (minutes)',
                hintText: 'e.g., 480 for 8 hours',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Resolution time is required';
                }
                final minutes = int.tryParse(value);
                if (minutes == null || minutes <= 0) {
                  return 'Please enter a valid number of minutes';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Active Status
            CheckboxListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value ?? true);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _savePolicy,
                    child: Text(_isCreating ? 'Create' : 'Update'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _savePolicy() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final policy = SlaPolicyV7(
        id: _editingPolicy?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        responseTime: Duration(minutes: int.parse(_responseTimeController.text)),
        resolutionTime: Duration(minutes: int.parse(_resolutionTimeController.text)),
        isActive: _isActive,
        businessHours: _editingPolicy?.businessHours ?? BusinessHours(),
        escalationRules: _editingPolicy?.escalationRules ?? [],
        createdAt: _editingPolicy?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _service.upsertPolicy(policy);
      
      if (!mounted) return;
      
      Navigator.pop(context);
      _loadPolicies();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCreating ? 'Policy created successfully' : 'Policy updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePolicy(SlaPolicyV7 policy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Policy'),
        content: Text('Are you sure you want to delete "${policy.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _service.deletePolicy(policy.id);
      _loadPolicies();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Policy deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SLA Policies'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPolicies,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _policies.isEmpty
              ? _buildEmptyState()
              : _buildPoliciesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPolicyForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.policy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No SLA Policies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first SLA policy to define response and resolution time expectations.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _showPolicyForm(),
            child: const Text('Create Policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _policies.length,
      itemBuilder: (context, index) {
        final policy = _policies[index];
        return _buildPolicyCard(policy);
      },
    );
  }

  Widget _buildPolicyCard(SlaPolicyV7 policy) {
    final priorityColor = _getPriorityColor(policy.priority);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor,
          child: Icon(
            Icons.policy,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                policy.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!policy.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'INACTIVE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (policy.description.isNotEmpty)
              Text(
                policy.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildTimeChip('Response', policy.responseTime, Colors.blue),
                const SizedBox(width: 8),
                _buildTimeChip('Resolution', policy.resolutionTime, Colors.green),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    policy.priority.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated ${_formatRelativeTime(policy.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handlePolicyAction(action, policy),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(policy.isActive ? Icons.pause : Icons.play_arrow),
                  SizedBox(width: 8),
                  Text(policy.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, Duration duration, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: ${_formatDuration(duration)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handlePolicyAction(String action, SlaPolicyV7 policy) {
    switch (action) {
      case 'edit':
        _showPolicyForm(policy: policy);
        break;
      case 'toggle':
        _togglePolicyStatus(policy);
        break;
      case 'delete':
        _deletePolicy(policy);
        break;
    }
  }

  Future<void> _togglePolicyStatus(SlaPolicyV7 policy) async {
    try {
      final updatedPolicy = SlaPolicyV7(
        id: policy.id,
        name: policy.name,
        description: policy.description,
        priority: policy.priority,
        responseTime: policy.responseTime,
        resolutionTime: policy.resolutionTime,
        isActive: !policy.isActive,
        businessHours: policy.businessHours,
        escalationRules: policy.escalationRules,
        createdAt: policy.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await _service.upsertPolicy(updatedPolicy);
      _loadPolicies();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedPolicy.isActive ? 'Policy activated' : 'Policy deactivated',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
