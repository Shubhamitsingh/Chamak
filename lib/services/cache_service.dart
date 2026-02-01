import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing app cache
/// Handles cache size calculation and clearing
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// Get formatted cache size (e.g., "45.2 MB" or "1.5 KB")
  Future<String> getCacheSize() async {
    try {
      final totalSize = await _calculateTotalCacheSize();
      return _formatSize(totalSize);
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 'Unknown';
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSizeInBytes() async {
    try {
      return await _calculateTotalCacheSize();
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Clear all cache and return statistics
  /// Returns: {'cleared': size in bytes, 'formatted': 'X.X MB'}
  Future<Map<String, dynamic>> clearCache() async {
    try {
      final sizeBefore = await _calculateTotalCacheSize();
      
      // Clear image cache
      await _clearImageCache();
      
      // Clear temporary files
      await _clearTempFiles();
      
      // Clear Flutter cache manager cache
      await _clearFlutterCacheManager();
      
      final sizeAfter = await _calculateTotalCacheSize();
      final clearedSize = sizeBefore - sizeAfter;
      
      return {
        'success': true,
        'cleared': clearedSize,
        'formatted': _formatSize(clearedSize),
        'before': sizeBefore,
        'after': sizeAfter,
      };
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return {
        'success': false,
        'error': e.toString(),
        'cleared': 0,
        'formatted': '0 B',
      };
    }
  }

  /// Calculate total cache size
  Future<int> _calculateTotalCacheSize() async {
    int totalSize = 0;
    
    try {
      // Get app cache directory
      final cacheDir = await _getCacheDirectory();
      if (cacheDir.existsSync()) {
        totalSize += await _getDirectorySize(cacheDir);
      }
      
      // Get temp directory
      final tempDir = await _getTempDirectory();
      if (tempDir.existsSync()) {
        totalSize += await _getDirectorySize(tempDir);
      }
      
      // Get image cache directory (cached_network_image)
      final imageCacheDir = await _getImageCacheDirectory();
      if (imageCacheDir.existsSync()) {
        totalSize += await _getDirectorySize(imageCacheDir);
      }
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
    }
    
    return totalSize;
  }

  /// Get directory size recursively
  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    
    try {
      if (!dir.existsSync()) return 0;
      
      final files = dir.listSync(recursive: true);
      for (var file in files) {
        if (file is File) {
          try {
            size += await file.length();
          } catch (e) {
            // Skip files that can't be accessed
            debugPrint('Error getting file size: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating directory size: $e');
    }
    
    return size;
  }

  /// Clear image cache (cached_network_image)
  Future<void> _clearImageCache() async {
    try {
      // Clear image cache directory (disk cache)
      final imageCacheDir = await _getImageCacheDirectory();
      if (imageCacheDir.existsSync()) {
        await imageCacheDir.delete(recursive: true);
        // Recreate directory
        await imageCacheDir.create(recursive: true);
      }
      
      // Note: In-memory cache will be cleared automatically
      // when app restarts or when images are reloaded
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  /// Clear temporary files
  Future<void> _clearTempFiles() async {
    try {
      final tempDir = await _getTempDirectory();
      if (tempDir.existsSync()) {
        final files = tempDir.listSync();
        for (var file in files) {
          try {
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (e) {
            // Skip files that can't be deleted
            debugPrint('Error deleting temp file: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing temp files: $e');
    }
  }

  /// Clear Flutter Cache Manager cache
  Future<void> _clearFlutterCacheManager() async {
    try {
      // Additional cache clearing if needed
      // This is a placeholder for future cache manager integration
    } catch (e) {
      debugPrint('Error clearing Flutter cache manager: $e');
    }
  }

  /// Get app cache directory
  Future<Directory> _getCacheDirectory() async {
    final dir = await getTemporaryDirectory();
    return dir;
  }

  /// Get temp directory
  Future<Directory> _getTempDirectory() async {
    final dir = await getTemporaryDirectory();
    return dir;
  }

  /// Get image cache directory (cached_network_image)
  Future<Directory> _getImageCacheDirectory() async {
    final cacheDir = await getTemporaryDirectory();
    // cached_network_image stores cache in libCachedImageData subdirectory
    return Directory('${cacheDir.path}/libCachedImageData');
  }

  /// Format bytes to human-readable size
  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
