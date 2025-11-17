import 'package:flutter/material.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool commentNotifications = true;
  bool newFollowersNotifications = true;
  bool likeAndFavouriteNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.notificationSettings,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildNotificationItem(
            title: AppLocalizations.of(context)!.comment,
            value: commentNotifications,
            onChanged: (value) {
              setState(() {
                commentNotifications = value;
              });
            },
          ),
          _buildNotificationItem(
            title: AppLocalizations.of(context)!.newFollowers,
            value: newFollowersNotifications,
            onChanged: (value) {
              setState(() {
                newFollowersNotifications = value;
              });
            },
          ),
          _buildNotificationItem(
            title: AppLocalizations.of(context)!.likeAndFavourite,
            value: likeAndFavouriteNotifications,
            onChanged: (value) {
              setState(() {
                likeAndFavouriteNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      trailing: Switch(
        value: value,
        activeColor: const Color(0xFF9C27B0), // purple instead of green
        onChanged: onChanged,
      ),
    );
  }
}

