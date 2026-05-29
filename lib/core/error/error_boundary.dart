import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String screenName;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    required this.screenName,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ??
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text('Something went wrong'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    setState(() => _error = null);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }
    return widget.child;
  }
}
