import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import 'performance_dashboard_screen.dart';
import '../services/cache_service.dart';
import '../widgets/clear_cache_dialog.dart';

class GeneralScreen extends StatefulWidget {
  const GeneralScreen({super.key});

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> {
  final CacheService _cacheService = CacheService();
  String _cacheSize = 'Calculating...';
  bool _isLoadingCacheSize = true;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    try {
      final size = await _cacheService.getCacheSize();
      if (mounted) {
        setState(() {
          _cacheSize = size;
          _isLoadingCacheSize = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSize = 'Unknown';
          _isLoadingCacheSize = false;
        });
      }
    }
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await ClearCacheDialog.show(context, _cacheSize);
    
    if (confirmed == true) {
      // Show progress dialog
      ClearCacheDialog.showProgress(context);
      
      // Clear cache
      final result = await _cacheService.clearCache();
      
      if (mounted) {
        if (result['success'] == true) {
          // Show success
          ClearCacheDialog.showSuccess(context, result['formatted']);
          
          // Refresh cache size
          await _loadCacheSize();
        } else {
          // Show error
          ClearCacheDialog.showError(
            context,
            result['error'] ?? 'Unknown error occurred',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to language changes to rebuild when language changes
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
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
              AppLocalizations.of(context)!.general,
              style: const TextStyle(
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
              
              // Clear Cache
              _buildSettingItem(
                title: 'Clear Cache',
                subtitle: _isLoadingCacheSize ? 'Calculating...' : _cacheSize,
                onTap: _showClearCacheDialog,
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
      },
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      dense: true,
      minVerticalPadding: 0,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.black38,
      ),
      onTap: onTap,
    );
  }
}
