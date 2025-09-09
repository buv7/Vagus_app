import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

class ClientListView extends StatefulWidget {
  final List<Map<String, dynamic>> clients;
  final Function(Map<String, dynamic>) onViewProfile;
  final Function(Map<String, dynamic>) onReview;
  final Function(Map<String, dynamic>) onMessage;

  const ClientListView({
    super.key,
    required this.clients,
    required this.onViewProfile,
    required this.onReview,
    required this.onMessage,
  });

  @override
  State<ClientListView> createState() => _ClientListViewState();
}

class _ClientListViewState extends State<ClientListView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: AppTheme.mintAqua,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.space8),
              Text(
                'Clients (${widget.clients.length})',
                style: const TextStyle(
                  color: AppTheme.neutralWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Page Indicator
              if (widget.clients.isNotEmpty)
                Text(
                  '${_currentPage + 1} / ${widget.clients.length}',
                  style: TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space16),
          
          // Client List with PageView
          Expanded(
            child: widget.clients.isEmpty
                ? const Center(
                    child: Text(
                      'No clients found',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: widget.clients.length,
                        itemBuilder: (context, index) {
                          final client = widget.clients[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.space8,
                            ),
                            child: _buildClientCard(client),
                          );
                        },
                      ),
                      
                      // Navigation Arrows
                      if (widget.clients.length > 1) ...[
                        // Previous Arrow
                        if (_currentPage > 0)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: AppTheme.mintAqua,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Next Arrow
                        if (_currentPage < widget.clients.length - 1)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.mintAqua,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
          
          // Page Dots Indicator
          if (widget.clients.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.clients.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space4,
                    ),
                    width: _currentPage == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppTheme.mintAqua
                          : AppTheme.steelGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final status = client['status'] as String;
    final statusColor = _getStatusColor(status);
    final compliance = client['compliance'] as int;
    final complianceColor = _getComplianceColor(compliance);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space12),
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Client Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.mintAqua,
                  borderRadius: BorderRadius.circular(DesignTokens.radius8),
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: DesignTokens.space12),
              
              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          client['name'],
                          style: const TextStyle(
                            color: AppTheme.neutralWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.space6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space6,
                            vertical: DesignTokens.space2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(DesignTokens.radius6),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      client['email'],
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      '${client['program']} • Joined ${client['joinDate']}',
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space6),
                    
                    // Tags
                    Wrap(
                      spacing: DesignTokens.space6,
                      runSpacing: DesignTokens.space2,
                      children: (client['tags'] as List<String>).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space6,
                            vertical: DesignTokens.space2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.steelGrey,
                            borderRadius: BorderRadius.circular(DesignTokens.radius6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppTheme.neutralWhite,
                              fontSize: 9,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // More Options
              IconButton(
                onPressed: () {
                  // Show more options
                },
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.lightGrey,
                  size: 20,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space12),
          
          // Progress and Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Progress',
                  value: client['progress'],
                  color: AppTheme.neutralWhite,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Compliance',
                  value: '${compliance}%',
                  color: complianceColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Last Active',
                  value: client['lastActive'],
                  color: AppTheme.lightGrey,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Next Session',
                  value: client['nextSession'],
                  color: AppTheme.mintAqua,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.space12),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onViewProfile(client), // Fixed Method Calls
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.steelGrey),
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onReview(client),
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppTheme.neutralWhite,
                    size: 14,
                  ),
                  label: const Text(
                    'Review',
                    style: TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.steelGrey),
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onMessage(client),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.neutralWhite,
                    size: 14,
                  ),
                  label: const Text(
                    'Message',
                    style: TextStyle(
                      color: AppTheme.neutralWhite,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.steelGrey),
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radius6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'paused':
        return AppTheme.steelGrey;
      case 'inactive':
        return Colors.red;
      default:
        return AppTheme.steelGrey;
    }
  }

  Color _getComplianceColor(int compliance) {
    if (compliance >= 90) return Colors.green;
    if (compliance >= 75) return Colors.orange;
    return Colors.red;
  }
}
