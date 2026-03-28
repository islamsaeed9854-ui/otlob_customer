import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/services/token_service.dart';
import '../providers/verify_otp_controller.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isPasswordReset;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  late final TextEditingController _emailController;
  bool _isLoadingEmail = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    if (widget.email.isEmpty) {
      _loadEmail();
    }
  }

  Future<void> _loadEmail() async {
    setState(() => _isLoadingEmail = true);
    final tokenService = ref.read(tokenServiceProvider);
    final email = await tokenService.getUserEmail();
    if (email != null && mounted) {
      setState(() {
        _emailController.text = email;
      });
    }
    if (mounted) setState(() => _isLoadingEmail = false);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final otp = _otpController.text.trim();
      final email = _emailController.text.trim();
      final success = await ref
          .read(verifyOtpControllerProvider.notifier)
          .verify(email, otp, isPasswordReset: widget.isPasswordReset);
      if (success && mounted) {
        if (widget.isPasswordReset) {
          context.push(
            RoutePaths.newPassword,
            extra: {'email': email, 'otp': otp},
          );
        } else {
          // It's part of registration verification. VerifyOtpController handles the token refresh.
          // The router will automatically redirect to home if auth status becomes verified.
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyOtpControllerProvider);

    ref.listen<AsyncValue<void>>(verifyOtpControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next is AsyncData && !next.isLoading && !widget.isPasswordReset) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Check your email',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_emailController.text.isNotEmpty)
                  Text(
                    'We sent a verification code to ${_emailController.text}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 32),
                if (_isLoadingEmail)
                  const Center(child: CircularProgressIndicator())
                else if (_emailController.text.isEmpty) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8.0,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    counterText: "",
                  ),
                  validator: (v) =>
                      (v == null || v.length < 4) ? 'Enter a valid code' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
