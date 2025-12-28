import 'dart:io';
import 'dart:convert';

class DebugLogger {
  static final String logPath = r'c:\Users\Shubham Singh\Desktop\chamak\.cursor\debug.log';
  
  static void log({
    required String location,
    required String message,
    Map<String, dynamic>? data,
    required String hypothesisId,
    String runId = 'run1',
    String sessionId = 'debug-session',
  }) {
    // Disabled to prevent file system errors on mobile devices
    // Logging causes performance issues and file system errors
    return;
  }
}



























