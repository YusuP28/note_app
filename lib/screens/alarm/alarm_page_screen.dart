import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlarmPageScreen extends StatefulWidget {
  const AlarmPageScreen({super.key});

  @override
  State<AlarmPageScreen> createState() => _AlarmPageScreenState();
}

class _AlarmPageScreenState extends State<AlarmPageScreen>
    with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('note_app/alarm_page');
  String _title = 'Pengingat';
  String _body = '';
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final t = await _channel.invokeMethod<String>('getTitle');
      final b = await _channel.invokeMethod<String>('getBody');
      if (mounted) {
        setState(() {
          _title = (t == null || t.isEmpty) ? 'Pengingat' : t;
          _body = b ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _stop() async {
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (_) {}
    if (mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _stop();
      },
      child: Scaffold(
        backgroundColor: scheme.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Icon(
                    Icons.alarm,
                    size: 120,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'PENGINGAT',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w300,
                    color: scheme.onPrimary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                ),
                if (_body.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _body,
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: scheme.onPrimary),
                    ),
                  ),
                ],
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton.icon(
                    onPressed: _stop,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.onPrimary,
                      foregroundColor: scheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    icon: const Icon(Icons.stop_circle, size: 32),
                    label: const Text(
                      'MATIKAN',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
