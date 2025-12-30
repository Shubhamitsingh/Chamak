import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../services/event_service.dart';
import '../services/announcement_tracking_service.dart';
import '../models/announcement_model.dart';
import '../screens/contact_support_chat_screen.dart';

class AnnouncementPanel extends StatefulWidget {
  const AnnouncementPanel({super.key});

  @override
  State<AnnouncementPanel> createState() => _AnnouncementPanelState();
}

class _AnnouncementPanelState extends State<AnnouncementPanel> {
  final Set<String> _expandedAnnouncements = {}; // Track expanded announcements

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.7; // 70% width

    return GestureDetector(
      // Tap outside to close
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.black.withValues(alpha:0.5), // Dark overlay
        child: GestureDetector(
          // Prevent tap from closing when tapping inside panel
          onTap: () {},
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              // Swipe right to close
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 300) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: panelWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.3),
                      blurRadius: 20,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(context),
                    
                    // Need Help? Chat Support Container (Separate container)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(); // Close announcements panel first
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ContactSupportChatScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            constraints: const BoxConstraints(maxWidth: 320),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF69B4), Color(0xFFFF1B7C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              const Icon(
                                Icons.support_agent_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Need Help? Chat Support',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Announcements List (Now with real Firebase data!)
                    Expanded(
                      child: _buildAnnouncementsList(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x80E91E63),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.announcements,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.stayUpdated,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.9),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Close Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList(BuildContext context) {
    final EventService eventService = EventService();
    final AnnouncementTrackingService trackingService = AnnouncementTrackingService();

    return StreamBuilder<List<AnnouncementModel>>(
      stream: eventService.getAnnouncementsStream(),
      builder: (context, announcementSnapshot) {
        return StreamBuilder<Set<String>>(
          stream: trackingService.getDismissedAnnouncementIdsStream(),
          builder: (context, dismissedSnapshot) {
            final snapshot = announcementSnapshot;
            final dismissedIds = dismissedSnapshot.data ?? {};
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE91E63),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading announcements',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }

            // Get real announcements from Firebase
            final allAnnouncements = snapshot.data ?? [];
            
            // Filter out dismissed announcements only
            final firebaseAnnouncements = allAnnouncements
                .where((a) => !dismissedIds.contains(a.id))
                .toList();

            // If no Firebase announcements, show empty state (NO FALLBACK!)
            if (firebaseAnnouncements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Announcements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for updates',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show real Firebase announcements with dismiss
            return ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: firebaseAnnouncements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final announcement = firebaseAnnouncements[index];
                final announcementMap = {
                  'id': announcement.id,
                  'title': announcement.title,
                  'description': announcement.description,
                  'date': announcement.date,
                  'time': announcement.time,
                  'isNew': announcement.isNew,
                  'color': announcement.color,
                  'icon': _getIconFromName(announcement.iconName),
                };
                return _buildAnnouncementCard(context, announcementMap, trackingService);
              },
            );
          },
        );
      },
    );
  }

  // Helper to convert icon name string to IconData
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'video_call':
        return Icons.video_call_rounded;
      case 'system_update':
        return Icons.system_update_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'notifications':
        return Icons.notifications_active_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'monetization_on':
        return Icons.monetization_on_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Widget _buildAnnouncementCard(
    BuildContext context, 
    Map<String, dynamic> announcement,
    AnnouncementTrackingService trackingService,
  ) {
    final color = Color(announcement['color']);
    final announcementId = announcement['id'] as String;
    final isExpanded = _expandedAnnouncements.contains(announcementId);

    // NO DISMISS FEATURE in home page announcement panel!
    // But can EXPAND to show full message
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedAnnouncements.remove(announcementId);
          } else {
            _expandedAnnouncements.add(announcementId);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: announcement['isNew'] 
                ? color.withValues(alpha:0.2) 
                : Colors.grey.withValues(alpha:0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon - Compact
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha:0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha:0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      announcement['icon'],
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Content (Expandable)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement['title'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Expandable description
                        AnimatedCrossFade(
                          firstChild: Text(
                            announcement['description'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            announcement['description'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            // No maxLines - shows full text!
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              announcement['time'],
                              style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 3,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              announcement['date'],
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            // Expand/Collapse indicator
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // New Badge - Smaller
            if (announcement['isNew'])
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha:0.8)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha:0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.newLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


