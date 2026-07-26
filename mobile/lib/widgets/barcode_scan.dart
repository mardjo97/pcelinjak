import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> scanBarcode(BuildContext context) async {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const _ScanPage()),
  );
}

/// Kontinuirano skenira barkodove u listu. Korisnik završava sa „Gotovo“.
Future<List<String>?> scanBarcodesContinuous(
  BuildContext context, {
  String title = 'Skeniraj košnice',
}) async {
  return Navigator.of(context).push<List<String>>(
    MaterialPageRoute(builder: (_) => _ContinuousScanPage(title: title)),
  );
}

class _ScanPage extends StatefulWidget {
  const _ScanPage();

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skeniraj barkod')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final raw = capture.barcodes.firstOrNull?.rawValue;
          if (raw == null || raw.isEmpty) return;
          _done = true;
          Navigator.pop(context, raw);
        },
      ),
    );
  }
}

class _ContinuousScanPage extends StatefulWidget {
  const _ContinuousScanPage({required this.title});

  final String title;

  @override
  State<_ContinuousScanPage> createState() => _ContinuousScanPageState();
}

class _ContinuousScanPageState extends State<_ContinuousScanPage> {
  final List<String> _codes = [];
  DateTime? _cooldownUntil;
  String? _flash;

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    final now = DateTime.now();
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) return;
    _cooldownUntil = now.add(const Duration(milliseconds: 1400));

    if (_codes.contains(raw)) {
      setState(() => _flash = 'Već u listi: $raw');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _codes.add(raw);
      _flash = 'Dodato: $raw';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_codes.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _codes.clear();
                _flash = null;
              }),
              child: const Text('Obriši listu'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(onDetect: _onDetect),
                if (_flash != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text(
                          _flash!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    _codes.isEmpty ? 'Skenirajte barkodove jedan za drugim' : '${_codes.length} u listi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: _codes.isEmpty
                      ? const Center(child: Text('Lista je prazna'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _codes.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final code = _codes[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                              ),
                              title: Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
                              trailing: IconButton(
                                tooltip: 'Ukloni',
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _codes.removeAt(i)),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton(
                      onPressed: _codes.isEmpty ? null : () => Navigator.pop(context, List<String>.from(_codes)),
                      child: Text(_codes.isEmpty ? 'Gotovo' : 'Gotovo (${_codes.length})'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
