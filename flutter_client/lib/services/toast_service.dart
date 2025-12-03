import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/colors.dart';

enum ToastType { success, error, info }

class ToastService {
  ToastService(this._overlayState);

  final OverlayState _overlayState;
  OverlayEntry? _entry;
  Timer? _timer;

  void show(String message, {ToastType type = ToastType.info, Duration? duration}) {
    _timer?.cancel();
    _entry?.remove();

    _entry = OverlayEntry(
      builder: (_) => _ToastWidget(message: message, type: type),
    );

    _overlayState.insert(_entry!);
    _timer = Timer(duration ?? const Duration(seconds: 3), hide);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _ToastWidget extends StatelessWidget {
  const _ToastWidget({required this.message, required this.type});

  final String message;
  final ToastType type;

  Color get _backgroundColor => switch (type) {
        ToastType.success => AppColors.success,
        ToastType.error => AppColors.error,
        ToastType.info => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 32,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: RepaintBoundary(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _backgroundColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 32,
                    color: Colors.black45,
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
