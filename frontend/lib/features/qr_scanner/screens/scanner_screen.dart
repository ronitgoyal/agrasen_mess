import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/scan_result_model.dart';
import '../services/scanner_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ScannerService _scannerService = const ScannerService();

  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    // Ek QR process ho raha ho to doosra scan na ho.
    if (_isProcessing) return;

    String? scannedValue;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.trim().isNotEmpty) {
        scannedValue = value.trim();
        break;
      }
    }

    if (scannedValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    await _cameraController.stop();

    try {
      final result = await _scannerService.scanQr(scannedValue);

      if (!mounted) return;

      await _showSuccessDialog(result);
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      await _showErrorDialog(message);
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    await _cameraController.start();
  }

  Future<void> _showSuccessDialog(ScanResultModel result) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 70),
          title: const Text('Attendance Recorded', textAlign: TextAlign.center),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(result.message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                _DetailRow(title: 'Student', value: result.studentName),
                _DetailRow(title: 'Room number', value: result.roomNumber),
                _DetailRow(
                  title: 'Meal',
                  value: _formatMealType(result.mealType),
                ),
                if (result.attendedAt != null)
                  _DetailRow(
                    title: 'Time',
                    value: _formatDateTime(result.attendedAt!),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Scan Next QR'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.cancel, color: Colors.red, size: 70),
          title: const Text('Scan Failed', textAlign: TextAlign.center),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(message, textAlign: TextAlign.center),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Scan Again'),
            ),
          ],
        );
      },
    );
  }

  String _formatMealType(String value) {
    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}'
                    '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatDateTime(DateTime value) {
    final localValue = value.toLocal();

    final day = localValue.day.toString().padLeft(2, '0');

    final month = localValue.month.toString().padLeft(2, '0');

    final minute = localValue.minute.toString().padLeft(2, '0');

    final hour = localValue.hour;
    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    return '$day/$month/${localValue.year} '
        '$displayHour:$minute $period';
  }

  Future<void> _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flashlight is unavailable.')),
      );
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraController.switchCamera();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not switch cameras.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Student QR'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: _toggleTorch,
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = constraints.biggest.shortestSide;

          // clamp() num return karta hai,
          // isliye toDouble() zaroori hai.
          final scannerSize = (shortestSide * 0.70)
              .clamp(210.0, 340.0)
              .toDouble();

          final bottomPadding = MediaQuery.paddingOf(context).bottom;

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _cameraController,
                onDetect: _handleDetection,
              ),

              // Camera ke upar light dark overlay.
              IgnorePointer(
                child: Container(color: Colors.black.withValues(alpha: 0.25)),
              ),

              // Responsive scanner frame.
              Center(
                child: IgnorePointer(
                  child: Container(
                    width: scannerSize,
                    height: scannerSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? Colors.orange : Colors.green,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Stack(
                      children: [
                        _ScannerCorner(
                          alignment: Alignment.topLeft,
                          color: _isProcessing ? Colors.orange : Colors.white,
                        ),
                        _ScannerCorner(
                          alignment: Alignment.topRight,
                          color: _isProcessing ? Colors.orange : Colors.white,
                        ),
                        _ScannerCorner(
                          alignment: Alignment.bottomLeft,
                          color: _isProcessing ? Colors.orange : Colors.white,
                        ),
                        _ScannerCorner(
                          alignment: Alignment.bottomRight,
                          color: _isProcessing ? Colors.orange : Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom instruction card.
              Positioned(
                left: 20,
                right: 20,
                bottom: bottomPadding + 25,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      color: Colors.black87,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessing) ...[
                              const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Flexible(
                              child: Text(
                                _isProcessing
                                    ? 'Recording attendance...'
: 'Position the student’s QR code within the frame',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final Alignment alignment;
  final Color color;

  const _ScannerCorner({required this.alignment, required this.color});

  @override
  Widget build(BuildContext context) {
    const double cornerLength = 38;
    const double thickness = 5;

    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;

    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: cornerLength,
        height: cornerLength,
        child: Stack(
          children: [
            Positioned(
              top: isTop ? 0 : null,
              bottom: isTop ? null : 0,
              left: 0,
              right: 0,
              child: Container(
                height: thickness,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Positioned(
              left: isLeft ? 0 : null,
              right: isLeft ? null : 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: thickness,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
