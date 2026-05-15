import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/login_controller.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/l10n/app_strings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _saveInfo = true;
  Map<String, String>? _savedProfile;

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    final profile = await ref.read(authRepositoryProvider).getSavedProfile();
    if (profile != null) {
      setState(() {
        _savedProfile = profile;
        _emailController.text = profile['email'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final result = await ref
          .read(loginControllerProvider.notifier)
          .login(
            email: email,
            password: password,
          );
      
      if (result && _saveInfo) {
        // If login was successful, save info
        await ref.read(authRepositoryProvider).saveProfileInfo(
          email,
          password,
          email.split('@')[0],
          'CUSTOMER'
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.welcomeBack)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  s.loginToApp,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_savedProfile != null) ...[
                  InkWell(
                    onTap: () {
                      final email = _savedProfile!['email'] ?? '';
                      final password = _savedProfile!['password'] ?? '';
                      _emailController.text = email;
                      _passwordController.text = password;
                      
                      ref.read(loginControllerProvider.notifier).login(
                        email: email.trim(),
                        password: password,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: _buildSavedProfileCard(s),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      s.orLoginWithAnother,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: s.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? s.emailRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: s.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? s.passwordMinLen : null,
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      height: 24, width: 24,
                      child: Checkbox(
                        value: _saveInfo,
                        onChanged: (v) => setState(() => _saveInfo = v ?? false),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _saveInfo = !_saveInfo),
                      child: Text(
                        s.rememberMe,
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(RoutePaths.forgotPassword),
                    child: Text(
                      s.forgotPassword,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loginState.isLoading ? null : _submit,
                    child: loginState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(s.login, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go(RoutePaths.register),
                  child: RichText(
                    text: TextSpan(
                      text: s.dontHaveAccount,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: s.signUp,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildSavedProfileCard(AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              _savedProfile!['name']?[0].toUpperCase() ?? 'U',
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _savedProfile!['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _savedProfile!['email'] ?? '',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              await ref.read(authRepositoryProvider).deleteSavedProfile();
              setState(() {
                _savedProfile = null;
              });
            },
          ),
        ],
      ),
    );
  }
}