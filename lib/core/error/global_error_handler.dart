import 'package:flutter/foundation.dart';
import 'error_logger.dart';

class GlobalErrorHandler {
  static void init() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      ErrorLogger.logError(
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      ErrorLogger.logError(
        error.toString(),
        error: error,
        stackTrace: stack,
      );
      return true;
    };
  }

  static void captureException(Object error, StackTrace stack) {
    ErrorLogger.logError(
      error.toString(),
      error: error,
      stackTrace: stack,
    );
  }
}
