import 'package:flutter/material.dart';

/// Full-screen dim + spinner. Blocks taps while [busy].
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({
    super.key,
    required this.busy,
    required this.child,
    this.message,
  });

  final bool busy;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (busy)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.38),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            if (message != null && message!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Spinner + label for a Filled/Outlined button while work is in progress.
class BusyButtonChild extends StatelessWidget {
  const BusyButtonChild({
    super.key,
    required this.busy,
    required this.label,
    required this.busyLabel,
  });

  final bool busy;
  final String label;
  final String busyLabel;

  @override
  Widget build(BuildContext context) {
    if (!busy) return Text(label);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Text(busyLabel),
      ],
    );
  }
}
