import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/qr_token_model.dart';
import '../services/qr_service.dart';

class QrScreen extends StatefulWidget {
  final int mealSlotId;
  final String mealType;

  const QrScreen({super.key, required this.mealSlotId, required this.mealType});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  static const MethodChannel _screenSecurityChannel = MethodChannel(
    'com.example.hostel_mess_app/screen_security',
  );

  Future<void> _enableScreenSecurity() async {
    try {
      await _screenSecurityChannel.invokeMethod('enableSecure');
    } on PlatformException catch (error) {
      debugPrint('Could not enable screen security: ${error.message}');
    }
  }

  Future<void> _disableScreenSecurity() async {
    try {
      await _screenSecurityChannel.invokeMethod('disableSecure');
    } on PlatformException catch (error) {
      debugPrint('Could not disable screen security: ${error.message}');
    }
  }

  final QrService _qrService = const QrService();

  QrTokenModel? _qrToken;
  Timer? _timer;

  bool _isLoading = true;
  String? _errorMessage;
  Duration _remainingTime = Duration.zero;

  DateTime? _countdownStartedAt;
  Duration _initialRemainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
    _generateQr();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disableScreenSecurity();
    super.dispose();
  }

  Future<void> _generateQr() async {
    _timer?.cancel();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _qrToken = null;
      _remainingTime = Duration.zero;
    });

    try {
      final qrToken = await _qrService.generateQr(
        mealSlotId: widget.mealSlotId,
      );

      if (!mounted) return;

      if (qrToken.token.isEmpty) {
        throw Exception('The server response did not include a QR token.');
      }

      setState(() {
        _qrToken = qrToken;
        _isLoading = false;
      });

      _countdownStartedAt = DateTime.now();

      _initialRemainingTime = qrToken.expiresAt.difference(qrToken.serverTime);

      _startCountdown();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startCountdown() {
    _updateRemainingTime();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingTime(),
    );
  }

  void _updateRemainingTime() {
    final startedAt = _countdownStartedAt;

    if (_qrToken == null || startedAt == null) return;

    final elapsed = DateTime.now().difference(startedAt);

    final difference = _initialRemainingTime - elapsed;

    if (!mounted) return;

    if (difference.isNegative || difference.inSeconds == 0) {
      _timer?.cancel();

      setState(() {
        _remainingTime = Duration.zero;
      });

      return;
    }

    setState(() {
      _remainingTime = difference;
    });
  }

  bool get _isExpired {
    return _qrToken != null && _remainingTime.inSeconds <= 0;
  }

  String get _formattedTime {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _mealTitle {
    if (widget.mealType.isEmpty) return 'Meal';

    return widget.mealType
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}'
                    '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_mealTitle QR Code'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating QR code...'),
        ],
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_qrToken == null) {
      return _buildError();
    }

    return _buildQrCard();
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 70),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Could not generate the QR code.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.red),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _generateQr,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    final qrToken = _qrToken!;

    final screenWidth = MediaQuery.sizeOf(context).width;

    final availableWidth = screenWidth - 96;

    final qrSize = availableWidth.clamp(180.0, 280.0);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _mealTitle,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Show this QR code to the mess in-charge for scanning.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (!_isExpired && !qrToken.isUsed)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: qrToken.qrValue,
                  version: QrVersions.auto,
                  size: qrSize,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              )
            else
              Container(
                width: qrSize,
                height: qrSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'QR Expired',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            if (!_isExpired && !qrToken.isUsed) ...[
              const Text('QR expiry time'),
              const SizedBox(height: 6),
              Text(
                _formattedTime,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const Text(
                'This QR code is no longer valid.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _generateQr,
                icon: const Icon(Icons.refresh),
                label: const Text('Generate New QR'),
              ),
            ],

            const SizedBox(height: 16),

            // Text(
            //  'Meal Slot ID: ${widget.mealSlotId}',
              // style: TextStyle(color: Colors.grey.shade600),
            // ),
          ],
        ),
      ),
    );
  }
}
