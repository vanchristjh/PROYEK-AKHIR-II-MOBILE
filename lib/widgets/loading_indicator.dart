import 'package:flutter/material.dart';
import 'dart:async';

class LoadingIndicator extends StatefulWidget {
  final Color? color;
  final double size;
  final double strokeWidth;
  final Duration? timeout;
  final Widget? timeoutWidget;
  final VoidCallback? onTimeout;
  
  const LoadingIndicator({
    super.key, 
    this.color,
    this.size = 24.0,
    this.strokeWidth = 3.0,
    this.timeout,
    this.timeoutWidget,
    this.onTimeout,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  bool _isTimedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _setupTimeout();
  }

  void _setupTimeout() {
    if (widget.timeout != null) {
      _timeoutTimer = Timer(widget.timeout!, () {
        if (mounted) {
          setState(() {
            _isTimedOut = true;
          });
          
          if (widget.onTimeout != null) {
            widget.onTimeout!();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useColor = widget.color ?? Theme.of(context).primaryColor;
    
    if (_isTimedOut && widget.timeoutWidget != null) {
      return widget.timeoutWidget!;
    }
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: widget.strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(useColor),
      ),
    );
  }
}
