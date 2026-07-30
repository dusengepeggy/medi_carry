import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    // Only QR. Scanning for every symbology slows detection down and lets a
    // barcode on a pill packet trip the handler.
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handling = false;
  bool _torchOn = false;

  /// Set once a code has been seen that is a valid QR but not a MediCarry
  /// share, so the screen can explain that instead of appearing to do nothing.
  String? _hint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// The camera has to be released when the app goes to the background, or
  /// Android hands back a frozen preview on resume — which looks exactly like
  /// a scanner that has stopped detecting anything.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_handling) unawaited(_controller.start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_controller.stop());
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty)
        .firstOrNull;
    if (raw == null) return;

    if (!raw.trim().startsWith(ShareCrypto.prefix)) {
      // A real QR, just not ours. Say so — silence here is what makes the
      // scanner feel broken.
      if (mounted) {
        setState(() => _hint =
            'That QR is not a MediCarry share code. Ask the patient to open '
            'MediCarry → Share Records → Show QR.');
      }
      return;
    }

    setState(() {
      _handling = true;
      _hint = null;
    });
    await _controller.stop();
    await _handleCode(raw.trim());
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
        _error('This share has expired. Ask the patient for a new code.');
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: '4-digit PIN from the patient',
            counterText: '',
          ),
          onSubmitted: (value) =>
              Navigator.of(dialogContext).pop(value.trim()),
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

  /// Manual fallback for a damaged code, a device with no usable camera, or a
  /// code that arrived as text.
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
    if (code == null) return;
    if (code.startsWith(ShareCrypto.prefix)) {
      await _controller.stop();
      if (mounted) setState(() => _handling = true);
      await _handleCode(code);
    } else {
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
            onPressed: () async {
              await _controller.toggleTorch();
              if (mounted) setState(() => _torchOn = !_torchOn);
            },
            tooltip: _torchOn ? 'Turn off torch' : 'Turn on torch',
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
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
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) =>
                _CameraError(error: error, onEnterManually: _enterManually),
          ),
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
              _hint ??
                  'Point the camera at the patient’s QR code, then enter the '
                      'PIN they give you. Works offline.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 20 / 14,
                color: _hint == null
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.limeFinal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown in place of the preview when the camera cannot start — most often a
/// denied permission, which otherwise presents as a black screen.
class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onEnterManually});

  final MobileScannerException error;
  final VoidCallback onEnterManually;

  String get _message => switch (error.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
          'MediCarry needs camera access to scan a shared code. Enable the '
              'camera permission in your phone’s settings, then come back.',
        MobileScannerErrorCode.unsupported =>
          'This device cannot scan QR codes. You can paste the code instead.',
        _ => 'The camera could not be started. You can paste the code instead.',
      };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: Colors.white70, size: 40),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  height: 22 / 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onEnterManually,
                icon: const Icon(Icons.keyboard, color: AppColors.limeFinal),
                label: Text(
                  'Paste the code',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.limeFinal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
