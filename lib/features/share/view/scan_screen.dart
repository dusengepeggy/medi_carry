import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/share_crypto.dart';
import '../../../core/theme/app_colors.dart';
import '../models/share_payload.dart';
import 'shared_record_view.dart';

/// Recipient-side scanner. Reads a MediCarry QR, asks for the PIN the patient
/// read aloud, decrypts the offline payload, and shows the read-only view.
/// Accountless and fully offline.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !raw.startsWith(ShareCrypto.prefix)) return;
    setState(() => _handling = true);
    await _controller.stop();
    await _handleCode(raw);
  }

  /// Prompt → decrypt → validate → show, with the camera re-armed on any
  /// recoverable failure.
  Future<void> _handleCode(String code) async {
    final pin = await _askPin();
    if (pin == null) {
      await _resume();
      return;
    }
    try {
      final json = ShareCrypto.decryptFromCode(code, pin);
      final payload = SharePayload.decode(json);
      if (payload.isExpired) {
        _error('This share has expired.');
        await _resume();
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SharedRecordView(payload: payload),
        ),
      );
      await _resume();
    } on ShareDecryptException catch (e) {
      _error(e.message);
      await _resume();
    } catch (_) {
      _error('That code could not be read.');
      await _resume();
    }
  }

  Future<void> _resume() async {
    if (!mounted) return;
    setState(() => _handling = false);
    await _controller.start();
  }

  void _error(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _askPin() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            hintText: '4-digit PIN from the patient',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  /// Manual fallback for platforms/devices without a usable camera (e.g. web).
  Future<void> _enterManually() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paste code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'MEDICARRY:1:…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (code != null && code.startsWith(ShareCrypto.prefix)) {
      await _handleCode(code);
    } else if (code != null) {
      _error('That is not a MediCarry code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan shared code',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _enterManually,
            tooltip: 'Enter code manually',
            icon: const Icon(Icons.keyboard),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Reticle.
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.limeFinal, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Text(
              'Point the camera at the patient’s QR code, then enter the '
              'PIN they give you. Works offline.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 20 / 14,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
