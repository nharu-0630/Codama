import 'package:codama/core/constants/config.dart';
import 'package:codama/core/providers/api_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupModal extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const SignupModal({super.key, required this.onSuccess});

  @override
  ConsumerState<SignupModal> createState() => _SignupModalState();
}

class _SignupModalState extends ConsumerState<SignupModal> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(Config.spacingXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: Config.spacingLarge,
          children: [
            Text(
              'Codama',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'あなたのふとした気づきが\nその土地の声になる',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Config.brandOrange,
                  foregroundColor: Config.neutralWhite,
                  padding: const EdgeInsets.symmetric(
                    vertical: Config.spacingLarge,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: Config.spacingXLarge,
                        width: Config.spacingXLarge,
                        child: CircularProgressIndicator(
                          color: Config.neutralWhite,
                          strokeWidth: Config.borderWidthThin,
                        ),
                      )
                    : Text(
                        '話しかけてみる',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Config.neutralWhite,
                        ),
                      ),
              ),
            ),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Config.neutralRed),
              ),
            ],
            Text(
              Config.baseUrl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = await ref.read(apiServiceProvider.future);
      await apiService.signUp();

      widget.onSuccess();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ネットワークエラーが発生しました: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
