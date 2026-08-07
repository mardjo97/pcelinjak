import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void dismissKeyboard() {
  final focus = FocusManager.instance.primaryFocus;
  focus?.unfocus();
  // Some Android keyboards stay open after unfocus alone.
  SystemChannels.textInput.invokeMethod('TextInput.hide');
}

/// Call from [TextField.onTapOutside].
void dismissKeyboardOnTapOutside(PointerDownEvent event) {
  if (_pointerHitsProtectedTarget(event)) return;
  dismissKeyboard();
}

bool _pointerHitsProtectedTarget(PointerDownEvent event) {
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderEditable) return true;
    if (target is RenderIgnoreKeyboardDismiss) return true;
  }
  return false;
}

/// App-wide: closes the soft keyboard when the user taps outside a text field.
class KeyboardDismissScope extends StatelessWidget {
  const KeyboardDismissScope({super.key, required this.child});

  final Widget child;

  void _handlePointerDown(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.hasFocus) return;
    if (_pointerHitsProtectedTarget(event)) return;
    dismissKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: child,
    );
  }
}

/// Wrap buttons/actions that should keep the keyboard open (e.g. suffix "+").
class IgnoreKeyboardDismiss extends SingleChildRenderObjectWidget {
  const IgnoreKeyboardDismiss({super.key, required Widget child})
    : super(child: child);

  @override
  RenderIgnoreKeyboardDismiss createRenderObject(BuildContext context) {
    return RenderIgnoreKeyboardDismiss();
  }
}

class RenderIgnoreKeyboardDismiss extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Ensure this marker stays in the hit path for ancestors' hit tests.
    return super.hitTest(result, position: position);
  }
}

/// Dismisses the keyboard on any pointer down (use around lists / empty areas,
/// not as an ancestor of a focused [TextField]).
class DismissKeyboardOnPointer extends StatelessWidget {
  const DismissKeyboardOnPointer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => dismissKeyboard(),
      child: child,
    );
  }
}

/// Unfocuses when [DefaultTabController] changes tab (tap or swipe).
class UnfocusOnTabChange extends StatefulWidget {
  const UnfocusOnTabChange({super.key, required this.child});

  final Widget child;

  @override
  State<UnfocusOnTabChange> createState() => _UnfocusOnTabChangeState();
}

class _UnfocusOnTabChangeState extends State<UnfocusOnTabChange> {
  TabController? _controller;
  int? _lastIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DefaultTabController.maybeOf(context);
    if (next == _controller) return;
    _controller?.removeListener(_onTabChanged);
    _controller = next;
    _lastIndex = next?.index;
    _controller?.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.indexIsChanging || controller.index != _lastIndex) {
      _lastIndex = controller.index;
      dismissKeyboard();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
