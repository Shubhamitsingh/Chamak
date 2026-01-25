import 'package:flutter/material.dart';
import '../services/in_app_update_service.dart';

/// Dialog shown when a flexible update has been downloaded
/// and the app needs to be restarted to apply the update
class UpdateRestartDialog extends StatelessWidget {
  const UpdateRestartDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Colors.green),
          SizedBox(width: 8),
          Text('Update Ready'),
        ],
      ),
      content: const Text(
        'A new version has been downloaded. Please restart the app to apply the update.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final updateService = InAppUpdateService();
              await updateService.checkForRestart();
              if (context.mounted) {
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error restarting app: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Restart Now'),
        ),
      ],
    );
  }
}
