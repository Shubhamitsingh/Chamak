import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String? description;
  final String actionType; // "navigate", "external_link", "deep_link", "none"
  final String? actionTarget;
  final int priority;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final BannerTargetAudience? targetAudience;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final int impressions;
  final int clicks;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.description,
    required this.actionType,
    this.actionTarget,
    required this.priority,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.targetAudience,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.impressions = 0,
    this.clicks = 0,
  });

  // Helper method to parse targetAudience (can be String or Map)
  // Also handles separate targetLevel, targetType, targetCountries fields
  static BannerTargetAudience? _parseTargetAudienceWithLevel(
    dynamic targetAudienceData,
    dynamic targetLevelData,
    dynamic targetTypeData,
    dynamic targetCountriesData,
  ) {
    int minLevel = 1;
    int maxLevel = 100;
    List<String> userTypes = ['all'];
    List<String> countries = [];
    
    // Parse targetLevel (can be Map with min/max or separate fields)
    if (targetLevelData != null) {
      if (targetLevelData is Map<String, dynamic>) {
        minLevel = targetLevelData['min'] as int? ?? 1;
        maxLevel = targetLevelData['max'] as int? ?? 100;
      }
    }
    
    // Parse userTypes (from targetAudience or targetType)
    if (targetTypeData != null) {
      if (targetTypeData is String) {
        userTypes = [targetTypeData];
      } else if (targetTypeData is List) {
        userTypes = targetTypeData.map((e) => e.toString()).toList();
      }
    } else if (targetAudienceData != null) {
      if (targetAudienceData is String) {
        userTypes = [targetAudienceData.toLowerCase() == 'all' ? 'all' : targetAudienceData];
      } else if (targetAudienceData is Map<String, dynamic>) {
        if (targetAudienceData['userTypes'] != null) {
          userTypes = List<String>.from(targetAudienceData['userTypes'] ?? ['all']);
        }
        if (targetAudienceData['minLevel'] != null) {
          minLevel = targetAudienceData['minLevel'] as int? ?? 1;
        }
        if (targetAudienceData['maxLevel'] != null) {
          maxLevel = targetAudienceData['maxLevel'] as int? ?? 100;
        }
      }
    }
    
    // Parse countries
    if (targetCountriesData != null) {
      if (targetCountriesData is List) {
        countries = targetCountriesData.map((e) => e.toString()).toList();
      }
    } else if (targetAudienceData != null && targetAudienceData is Map<String, dynamic>) {
      if (targetAudienceData['countries'] != null) {
        countries = List<String>.from(targetAudienceData['countries'] ?? []);
      }
    }
    
    return BannerTargetAudience(
      minLevel: minLevel,
      maxLevel: maxLevel,
      userTypes: userTypes,
      countries: countries,
    );
  }

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle image URL - check multiple field names (imageUrl, image, banner)
    String imageUrl = '';
    if (data['imageUrl'] != null) {
      imageUrl = data['imageUrl'] as String;
    } else if (data['image'] != null) {
      imageUrl = data['image'] as String;
    } else if (data['banner'] != null) {
      imageUrl = data['banner'] as String;
    }
    
    // Handle endDate - can be Timestamp or string
    DateTime? endDate;
    if (data['endDate'] != null) {
      if (data['endDate'] is Timestamp) {
        endDate = (data['endDate'] as Timestamp).toDate();
      } else if (data['endDate'] is String) {
        // Try parsing string date
        try {
          endDate = DateTime.parse(data['endDate'] as String);
        } catch (e) {
          // Invalid date string, leave as null
        }
      }
    }
    
    // Handle startDate - can be Timestamp or string
    DateTime? startDate;
    if (data['startDate'] != null) {
      if (data['startDate'] is Timestamp) {
        startDate = (data['startDate'] as Timestamp).toDate();
      } else if (data['startDate'] is String) {
        try {
          startDate = DateTime.parse(data['startDate'] as String);
        } catch (e) {
          // Invalid date string, leave as null
        }
      }
    }
    
    return BannerModel(
      id: doc.id,
      imageUrl: imageUrl,
      title: data['title'],
      description: data['description'],
      actionType: data['actionType'] ?? 'none',
      actionTarget: data['actionTarget'],
      priority: data['priority'] ?? 5, // Default to 5 if missing
      // Always default to true for isActive - admin panel might not set it correctly
      // This ensures banners show by default unless explicitly set to false AND you want to hide it
      isActive: (data['isActive'] as bool?) ?? true, // Default to true if missing or null
      startDate: startDate,
      endDate: endDate,
      targetAudience: _parseTargetAudienceWithLevel(
        data['targetAudience'],
        data['targetLevel'],
        data['targetType'],
        data['targetCountries'],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? 'admin',
      impressions: data['impressions'] ?? 0,
      clicks: data['clicks'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'actionType': actionType,
      'actionTarget': actionTarget,
      'priority': priority,
      'isActive': isActive,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'targetAudience': targetAudience?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'impressions': impressions,
      'clicks': clicks,
    };
  }

  // Check if banner should be shown to current user
  bool shouldShowToUser({
    required int userLevel,
    required String userType,
    required String? userCountry,
  }) {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    if (targetAudience != null) {
      if (userLevel < targetAudience!.minLevel || 
          userLevel > targetAudience!.maxLevel) {
        return false;
      }
      
      if (!targetAudience!.userTypes.contains('all') &&
          !targetAudience!.userTypes.contains(userType)) {
        return false;
      }
      
      if (targetAudience!.countries.isNotEmpty &&
          userCountry != null &&
          !targetAudience!.countries.contains(userCountry)) {
        return false;
      }
    }
    
    return true;
  }
}

class BannerTargetAudience {
  final int minLevel;
  final int maxLevel;
  final List<String> userTypes;
  final List<String> countries;

  BannerTargetAudience({
    required this.minLevel,
    required this.maxLevel,
    required this.userTypes,
    required this.countries,
  });

  factory BannerTargetAudience.fromMap(Map<String, dynamic> map) {
    return BannerTargetAudience(
      minLevel: map['minLevel'] ?? 1,
      maxLevel: map['maxLevel'] ?? 100,
      userTypes: List<String>.from(map['userTypes'] ?? ['all']),
      countries: List<String>.from(map['countries'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minLevel': minLevel,
      'maxLevel': maxLevel,
      'userTypes': userTypes,
      'countries': countries,
    };
  }
}
