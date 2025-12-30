import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../services/event_service.dart';
import '../services/announcement_tracking_service.dart';
import '../models/announcement_model.dart';
import '../models/event_model.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventService _eventService = EventService();
  final AnnouncementTrackingService _trackingService = AnnouncementTrackingService();
  final Set<String> _expandedAnnouncements = {}; // Track expanded announcements

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                onPressed: () {
                  try {
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error navigating back: $e');
                  }
                },
              ),
              title: Text(
                AppLocalizations.of(context)!.eventsAndAnnouncements,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              bottom: TabBar(
                controller: _tabController,
                // Use purple for active tab text/icons and a soft grey for inactive
                labelColor: const Color(0xFF8E24AA),
                unselectedLabelColor: Colors.grey[600],
                // Slightly thicker indicator in matching purple
                indicatorColor: const Color(0xFF8E24AA),
                indicatorWeight: 3.5,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.campaign_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(AppLocalizations.of(context)!.announcements),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(AppLocalizations.of(context)!.events),
                              ],
                            ),
                          ),
                        ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Announcements Tab
            _buildAnnouncementsTab(),
            // Events Tab
            _buildEventsTab(),
          ],
        ),
      ),
    );
  }


  Widget _buildEventsTab() {
    return StreamBuilder<List<EventModel>>(
      stream: _eventService.getEventsStream(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF69B4),
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
                  AppLocalizations.of(context)!.errorLoadingEvents,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }

        // Get events from Firebase
        final firebaseEvents = snapshot.data ?? [];

        // If no Firebase events, show empty state (NO FALLBACK!)
        if (firebaseEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.noEventsYet,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    AppLocalizations.of(context)!.eventsFromAdminWillAppear,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        // Show real Firebase events
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          itemCount: firebaseEvents.length,
          itemBuilder: (context, index) {
            final event = firebaseEvents[index];
            
            // DEBUG: Print event data
            debugPrint('🎉 [EventScreen] Event ${index + 1}:');
            debugPrint('   ID: ${event.id}');
            debugPrint('   Title: ${event.title}');
            debugPrint('   imageURL: ${event.imageURL}');
            debugPrint('   Has image: ${event.imageURL != null && event.imageURL!.isNotEmpty}');
            
            final eventMap = {
              'title': event.title,
              'description': event.description,
              'date': event.date,
              'startDate': event.startDate,
              'endDate': event.endDate,
              'time': event.time,
              'type': event.type,
              'isNew': event.isNew,
              'color': event.color,
              'participants': event.participants,
              'imageURL': event.imageURL, // Include image URL from Firebase!
            };
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == firebaseEvents.length - 1 ? 0 : 16),
              child: SizedBox(
                height: MediaQuery.of(context).size.width / 1.35,
                child: _buildEventPoster(eventMap),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsTab() {
            debugPrint('🎨 [EventScreen] Building announcements tab');
    
    return StreamBuilder<List<AnnouncementModel>>(
      stream: _eventService.getAnnouncementsStream(),
      builder: (context, snapshot) {
        debugPrint('🔄 [EventScreen] StreamBuilder state: ${snapshot.connectionState}');
        debugPrint('   Has data: ${snapshot.hasData}');
        debugPrint('   Has error: ${snapshot.hasError}');
        if (snapshot.hasData) {
          debugPrint('   Data count: ${snapshot.data!.length}');
        }
        if (snapshot.hasError) {
          debugPrint('   Error: ${snapshot.error}');
        }
        
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('⏳ [EventScreen] Waiting for data...');
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF69B4),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          debugPrint('❌ [EventScreen] Error in StreamBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingAnnouncements,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.errorOccurred,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    debugPrint('🔄 [EventScreen] Manual refresh triggered');
                    if (!mounted) return;
                    setState(() {});
                  },
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        // Get announcements from Firebase
        final firebaseAnnouncements = snapshot.data ?? [];

        // If no Firebase announcements, show empty state (NO FALLBACK!)
        if (firebaseAnnouncements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.noAnnouncementsYet,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    AppLocalizations.of(context)!.announcementsFromAdminWillAppear,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        // Show real Firebase announcements with dismiss option
        return StreamBuilder<Set<String>>(
          stream: _trackingService.getDismissedAnnouncementIdsStream(),
          builder: (context, dismissedSnapshot) {
            final dismissedIds = dismissedSnapshot.data ?? {};
            
            // Filter out dismissed announcements
            final visibleAnnouncements = firebaseAnnouncements
                .where((a) => !dismissedIds.contains(a.id))
                .toList();
            
            if (visibleAnnouncements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, 
                      size: 64, 
                      color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.allCaughtUp,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.noAnnouncementsToShow,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: visibleAnnouncements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final announcement = visibleAnnouncements[index];
                final announcementMap = {
                  'id': announcement.id,
                  'title': announcement.title,
                  'description': announcement.description,
                  'date': announcement.date,
                  'time': announcement.time,
                  'type': announcement.type,
                  'isNew': announcement.isNew,
                  'color': announcement.color,
                  'icon': _getIconFromName(announcement.iconName),
                };
                return _buildAnnouncementCard(announcementMap);
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
      default:
        return Icons.campaign_rounded;
    }
  }
  
  Widget _buildEventPoster(Map<String, dynamic> event) {
    final color = Color(event['color']);
    final imageURL = event['imageURL'] as String?;
    final hasImage = imageURL != null && imageURL.isNotEmpty;
    
    // DEBUG: Print poster build info
            debugPrint('🖼️ [_buildEventPoster] Building poster:');
            debugPrint('   Title: ${event['title']}');
            debugPrint('   imageURL: $imageURL');
            debugPrint('   hasImage: $hasImage');
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background - Image or Gradient
            if (hasImage)
              // Admin uploaded image
              Positioned.fill(
                child: Image.network(
                  imageURL,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha:0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient on error
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha:0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              // Default gradient background (no image)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha:0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            
            // Dark overlay on image for text readability
            if (hasImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha:0.5),
                        Colors.black.withValues(alpha:0.3),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            
            // Pattern Overlay (only if no image)
            if (!hasImage)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.network(
                    'https://www.transparenttextures.com/patterns/asfalt-light.png',
                    repeat: ImageRepeat.repeat,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Event Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.event.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // New Badge
                      if (event['isNew'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.newLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  Text(
                    event['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    event['description'],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.95),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Footer Info
                  Row(
                    children: [
                      // Date & Time
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Show both start and end dates if available
                                    if (event['startDate'] != null && event['endDate'] != null)
                                      Text(
                                        '${event['startDate']} - ${event['endDate']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else if (event['startDate'] != null)
                                      Text(
                                        '${AppLocalizations.of(context)!.from} ${event['startDate']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else if (event['endDate'] != null)
                                      Text(
                                        '${AppLocalizations.of(context)!.until} ${event['endDate']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else
                                      Text(
                                        event['date'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (event['time'] != null && event['time'].isNotEmpty)
                                      Text(
                                        event['time'],
                                        style: TextStyle(
                                        color: Colors.white.withValues(alpha:0.9),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Participants
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event['participants'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final color = Color(announcement['color']);
    final announcementId = announcement['id'] as String;
    final isExpanded = _expandedAnnouncements.contains(announcementId);
    
    return Dismissible(
      key: Key(announcementId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        // Dismiss announcement for this user
        await _trackingService.dismissAnnouncement(announcementId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.announcementDismissed),
                ],
              ),
              backgroundColor: const Color(0xFF04B104),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.dismiss,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (!mounted) return;
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
                children: [
                  // Icon - More compact
                  Container(
                    padding: const EdgeInsets.all(10),
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
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Content - More compact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement['title'],
                          style: const TextStyle(
                            fontSize: 13,
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
                              size: 11,
                              color: color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              announcement['time'],
                              style: TextStyle(
                                fontSize: 10,
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
                                fontSize: 10,
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
                    vertical: 3,
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
      ),
    );
  }

}

