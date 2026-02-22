import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/gift_service.dart';
import '../theme/app_constants.dart';

// Light theme — lavender/purple accents; font sizes/weights match app theme (Poppins)
const _kPurple = Color(0xFF8B7CFB);
const _kGold = Color(0xFFFFD700);
const _kSilver = Color(0xFFC0C0C0);
const _kBronze = Color(0xFFCD7F32);

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GiftService _giftService = GiftService();
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;
  bool _isDaily = true;

  /// Fake data (top to bottom) + 7 more users
  static List<Map<String, dynamic>> get _fakeData => [
        {'displayName': '******', 'photoURL': null, 'totalCCoins': 1175000, 'level': 0},
        {'displayName': 'Loooo', 'photoURL': null, 'totalCCoins': 1050000, 'level': 9},
        {'displayName': 'Angel Riya', 'photoURL': null, 'totalCCoins': 868000, 'level': 7},
        {'displayName': '******', 'photoURL': null, 'totalCCoins': 700000, 'level': 0},
        {'displayName': '******', 'photoURL': null, 'totalCCoins': 603312, 'level': 0},
        {'displayName': 'priya', 'photoURL': null, 'totalCCoins': 450000, 'level': 8},
        {'displayName': 'Shreya', 'photoURL': null, 'totalCCoins': 450000, 'level': 7},
        {'displayName': '******', 'photoURL': null, 'totalCCoins': 400000, 'level': 0},
        {'displayName': '******', 'photoURL': null, 'totalCCoins': 350000, 'level': 0},
        {'displayName': 'FLOra', 'photoURL': null, 'totalCCoins': 300000, 'level': 7},
        {'displayName': 'Neha', 'photoURL': null, 'totalCCoins': 265000, 'level': 6},
        {'displayName': '******', 'photoURL': null, 'totalCCoins': 220000, 'level': 0},
        {'displayName': 'Kavya', 'photoURL': null, 'totalCCoins': 185000, 'level': 5},
        {'displayName': '******', 'photoURL': null, 'totalCCoins': 150000, 'level': 0},
        {'displayName': 'Ananya', 'photoURL': null, 'totalCCoins': 120000, 'level': 5},
        {'displayName': '******', 'photoURL': null, 'totalCCoins': 95000, 'level': 0},
        {'displayName': 'Diya', 'photoURL': null, 'totalCCoins': 72000, 'level': 4},
      ];

  List<Map<String, dynamic>> get _displayList {
    if (_leaderboard.isNotEmpty) return _leaderboard;
    return _fakeData;
  }

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    try {
      final list = await _giftService.getHostLeaderboard(limit: 30);
      if (mounted) {
        setState(() {
          _leaderboard = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaderboard = [];
          _loading = false;
        });
      }
    }
  }

  String _formatCoins(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    var i = s.length % 3;
    if (i == 0) i = 3;
    buf.write(s.substring(0, i));
    for (; i < s.length; i += 3) {
      buf.write(',');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leaderboard',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.black87,
            fontSize: AppConstants.fontSizeXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPurple))
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
              color: _kPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPeriodChip(context, 'Daily', true),
                          const SizedBox(width: 6),
                          _buildPeriodChip(context, 'Monthly', false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildTopThree(context),
                    const SizedBox(height: 18),
                    _buildListHeader(context),
                    const SizedBox(height: 8),
                    _buildList(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, bool selected) {
    final isSelected = (label == 'Daily') ? _isDaily : !_isDaily;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        setState(() => _isDaily = (label == 'Daily'));
        _loadLeaderboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? _kPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          border: Border.all(
            color: isSelected ? _kPurple : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: AppConstants.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTopThree(BuildContext context) {
    final list = _displayList;
    final top3 = list.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (top3.length > 1) _buildPodiumItem(context, 2, top3[1], elevated: false),
        if (top3.isNotEmpty) _buildPodiumItem(context, 1, top3[0], elevated: true),
        if (top3.length > 2) _buildPodiumItem(context, 3, top3[2], elevated: false),
      ],
    );
  }

  Widget _buildPodiumItem(BuildContext context, int rank, Map<String, dynamic> entry, {bool elevated = false}) {
    final isFirst = rank == 1;
    final theme = Theme.of(context).textTheme;
    final crownColor = rank == 1 ? _kGold : rank == 2 ? _kSilver : _kBronze;
    final size = isFirst ? 72.0 : 48.0;
    final name = (entry['displayName'] as String?)?.trim();
    final showName = name != null && name.isNotEmpty && name != '******';
    final level = (entry['level'] as int?) ?? 0;
    final hasPhoto = entry['photoURL'] != null && (entry['photoURL'] as String).isNotEmpty;
    final crownSize = isFirst ? 36.0 : 26.0;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/crown.png',
          width: crownSize,
          height: crownSize,
          fit: BoxFit.contain,
          color: crownColor,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (_, __, ___) => Icon(Icons.emoji_events, color: crownColor, size: crownSize),
        ),
        const SizedBox(height: 4),
        Text(
          '($rank)',
          style: theme.bodySmall?.copyWith(
            fontSize: isFirst ? AppConstants.fontSizeSmall : 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kPurple,
            boxShadow: [
              BoxShadow(
                color: _kPurple.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: entry['photoURL'] as String,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    errorWidget: (_, __, ___) => Icon(Icons.person, size: size * 0.5, color: Colors.white),
                  )
                : Icon(Icons.person, size: size * 0.5, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            showName ? (entry['displayName'] as String) : '******',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium?.copyWith(
              fontSize: AppConstants.fontSizeMedium,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatCoins(entry['totalCCoins'] as int? ?? 0),
              style: theme.bodyMedium?.copyWith(
                fontSize: AppConstants.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 3),
            Image.asset(
              'assets/images/coin2.png',
              width: 14,
              height: 14,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.monetization_on, size: 14, color: Colors.amber[700]),
            ),
          ],
        ),
        if (level > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇮🇳', style: theme.bodySmall?.copyWith(fontSize: 10)),
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPurple,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Text(
                  '★Lv$level',
                  style: theme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
    if (elevated) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: content,
      );
    }
    return content;
  }

  Widget _buildListHeader(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'Rank #',
              style: theme.labelMedium?.copyWith(
                fontSize: AppConstants.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Expanded(child: SizedBox()),
          Text(
            'Beans',
            style: theme.labelMedium?.copyWith(
              fontSize: AppConstants.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final list = _displayList.length > 3 ? _displayList.sublist(3) : <Map<String, dynamic>>[];
    final theme = Theme.of(context).textTheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final entry = list[index];
        final rank = index + 4;
        final name = (entry['displayName'] as String?)?.trim();
        final showName = name != null && name.isNotEmpty && name != '******';
        final level = (entry['level'] as int?) ?? 0;
        final hasPhoto = entry['photoURL'] != null && (entry['photoURL'] as String).isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$rank',
                  style: theme.bodyMedium?.copyWith(
                    fontSize: AppConstants.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPurple,
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: entry['photoURL'] as String,
                          fit: BoxFit.cover,
                          width: 34,
                          height: 34,
                          placeholder: (_, __) => const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                          errorWidget: (_, __, ___) => Icon(Icons.person, size: 18, color: Colors.white),
                        )
                      : Icon(Icons.person, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showName ? (entry['displayName'] as String) : '******',
                      style: theme.bodyMedium?.copyWith(
                        fontSize: AppConstants.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (level > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Text('🇮🇳', style: theme.bodySmall?.copyWith(fontSize: 9)),
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: _kPurple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '★Lv$level',
                                style: theme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatCoins(entry['totalCCoins'] as int? ?? 0),
                    style: theme.bodyMedium?.copyWith(
                      fontSize: AppConstants.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Image.asset(
                    'assets/images/coin2.png',
                    width: 14,
                    height: 14,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.monetization_on, size: 14, color: Colors.amber[700]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
