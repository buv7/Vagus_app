import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/billing/plan_access_manager.dart';

class RankHubScreen extends StatefulWidget {
  const RankHubScreen({super.key});

  @override
  State<RankHubScreen> createState() => _RankHubScreenState();
}

class _RankHubScreenState extends State<RankHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkProStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkProStatus() async {
    final isPro = await PlanAccessManager.instance.isProUser();
    setState(() {
      _isPro = isPro;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rank Hub'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Theme.of(context).colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              tabs: const [
                Tab(text: 'Badges'),
                Tab(text: 'Season'),
                Tab(text: 'Leaderboard'),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBadgeGallery(),
                _buildSeasonLadder(),
                _buildLeaderboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGallery() {
    final badges = _isPro ? _getProBadges() : _getFreeBadges();
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, // Increased from 1.2 to prevent overflow
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _BadgeCard(
          title: badge['title'],
          description: badge['description'],
          icon: badge['icon'],
          isUnlocked: badge['unlocked'],
          isPro: badge['pro'] ?? false,
        );
      },
    );
  }

  Widget _buildSeasonLadder() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current season info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Season',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Season 1: Foundation',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Progress: 75%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Season rewards
        Text(
          'Season Rewards',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...List.generate(5, (index) => _SeasonRewardItem(
          level: index + 1,
          reward: _getSeasonReward(index + 1),
          isUnlocked: index < 3,
        )),
      ],
    );
  }

  Widget _buildLeaderboard() {
    final leaderboard = _getLeaderboardData();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Your position
        Card(
          color: AppTheme.primaryBlack.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Position',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '#${leaderboard.firstWhere((item) => item['isYou'] == true)['position']}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${leaderboard.firstWhere((item) => item['isYou'] == true)['points']} pts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Top 10
        Text(
          'Top 10',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...leaderboard.take(10).map((item) => _LeaderboardItem(
          position: item['position'],
          name: item['name'],
          points: item['points'],
          isYou: item['isYou'] ?? false,
        )),
      ],
    );
  }

  List<Map<String, dynamic>> _getFreeBadges() {
    return [
      {
        'title': 'First Steps',
        'description': 'Complete your first workout',
        'icon': Icons.fitness_center,
        'unlocked': true,
        'pro': false,
      },
      {
        'title': 'Consistency',
        'description': 'Work out 3 days in a row',
        'icon': Icons.repeat,
        'unlocked': true,
        'pro': false,
      },
      {
        'title': 'Pro Badge',
        'description': 'Upgrade to Pro for animated badges',
        'icon': Icons.star,
        'unlocked': false,
        'pro': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getProBadges() {
    return [
      ..._getFreeBadges(),
      {
        'title': 'Neon Warrior',
        'description': 'Complete 10 workouts with neon effects',
        'icon': Icons.electric_bolt,
        'unlocked': true,
        'pro': true,
      },
      {
        'title': 'Streak Master',
        'description': 'Maintain a 30-day streak',
        'icon': Icons.local_fire_department,
        'unlocked': false,
        'pro': true,
      },
      {
        'title': 'Elite',
        'description': 'Reach the top 1% of users',
        'icon': Icons.emoji_events,
        'unlocked': false,
        'pro': true,
      },
    ];
  }

  String _getSeasonReward(int level) {
    switch (level) {
      case 1:
        return 'Neon Badge Frame';
      case 2:
        return 'Custom Profile Theme';
      case 3:
        return 'Animated Streak Effects';
      case 4:
        return 'Exclusive Workout Plans';
      case 5:
        return 'Legendary Status';
      default:
        return 'Mystery Reward';
    }
  }

  List<Map<String, dynamic>> _getLeaderboardData() {
    return [
      {'position': 1, 'name': 'Alex Chen', 'points': 2847, 'isYou': false},
      {'position': 2, 'name': 'Sarah Kim', 'points': 2653, 'isYou': false},
      {'position': 3, 'name': 'Mike Johnson', 'points': 2412, 'isYou': false},
      {'position': 4, 'name': 'You', 'points': 2189, 'isYou': true},
      {'position': 5, 'name': 'Emma Davis', 'points': 1956, 'isYou': false},
      {'position': 6, 'name': 'David Wilson', 'points': 1843, 'isYou': false},
      {'position': 7, 'name': 'Lisa Brown', 'points': 1721, 'isYou': false},
      {'position': 8, 'name': 'Tom Garcia', 'points': 1598, 'isYou': false},
      {'position': 9, 'name': 'Anna Lee', 'points': 1476, 'isYou': false},
      {'position': 10, 'name': 'Chris Taylor', 'points': 1354, 'isYou': false},
    ];
  }
}

class _BadgeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final bool isPro;

  const _BadgeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
                  color: isUnlocked 
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: isUnlocked 
                    ? (isPro ? AppTheme.steelGrey : AppTheme.primaryBlack)
                    : Colors.grey,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked 
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUnlocked 
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPro && !isUnlocked) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.steelGrey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PRO',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.steelGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonRewardItem extends StatelessWidget {
  final int level;
  final String reward;
  final bool isUnlocked;

  const _SeasonRewardItem({
    required this.level,
    required this.reward,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isUnlocked ? AppTheme.primaryBlack : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isUnlocked ? Icons.check : Icons.lock,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Level $level',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          reward,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isUnlocked 
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                : Colors.grey,
          ),
        ),
        trailing: isUnlocked 
            ? const Icon(Icons.check_circle, color: AppTheme.primaryBlack)
            : null,
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final int position;
  final String name;
  final int points;
  final bool isYou;

  const _LeaderboardItem({
    required this.position,
    required this.name,
    required this.points,
    required this.isYou,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isYou ? AppTheme.primaryBlack.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getPositionColor(position),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isYou ? FontWeight.bold : FontWeight.normal,
            color: isYou ? AppTheme.primaryBlack : null,
          ),
        ),
        trailing: Text(
          '$points pts',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isYou ? AppTheme.primaryBlack : null,
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return AppTheme.primaryBlack;
    }
  }
}
