import 'package:flutter/material.dart';
import 'performance_dashboard_screen.dart';

class GeneralScreen extends StatelessWidget {
  const GeneralScreen({super.key});

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
        title: const Text(
          'General',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Performance
          _buildSettingItem(
            title: 'Performance',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PerformanceDashboardScreen(),
                ),
              );
            },
          ),
          
          // How to use Chamakz
          _buildSettingItem(
            title: 'How to use Chamakz',
            onTap: () {
              // TODO: Navigate to How to use Chamakz screen or show guide
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('How to use Chamakz guide coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.black38,
      ),
      onTap: onTap,
    );
  }
}
