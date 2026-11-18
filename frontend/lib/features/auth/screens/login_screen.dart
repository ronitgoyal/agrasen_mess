import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'forgot_password_screen.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _backgroundColor = Color(0xFFF7FAF8);

  static const Color _darkGreen = Color(0xFF18743F);

  static const Color _buttonGreen = Color(0xFF29934D);

  static const Color _orange = Color(0xFFFF7130);

  static const Color _textColor = Color(0xFF17231C);

  static const Color _mutedColor = Color(0xFF6D7D74);

  static const Color _logoBackground = Color(0xFFFFF3E8);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _hidePassword = !_hidePassword;
    });
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();

    final didReset = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );

    if (!mounted || didReset != true) return;

    _passwordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated. Login with your new password.'),
      ),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Invalid email or password'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required Widget prefixIcon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    const normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFF101813), width: 1.1),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _mutedColor,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),

      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),

      enabledBorder: normalBorder,

      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: _darkGreen, width: 1.6),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),

      // Validation message will not be cut.
      errorStyle: TextStyle(
        color: Colors.red.shade700,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w500,
      ),

      errorMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _darkGreen,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Column(
                      children: [
                        const SizedBox(height: 85),

                        // Hostel Mess logo

                        // Hostel Mess logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: _logoBackground,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/hostel_mess_logo.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) {
                                    return const Center(
                                      child: Text(
                                        'HM',
                                        style: TextStyle(
                                          color: _orange,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          'Shri Agrasen Hostel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _darkGreen,
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Fresh meals. Simple access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _mutedColor,
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Login card
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          constraints: const BoxConstraints(minHeight: 350),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email label
                                  const Text(
                                    'EMAIL ADDRESS',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontSize: 12,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(height: 7),

                                  // Email field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    style: const TextStyle(
                                      color: _textColor,
                                      fontSize: 15,
                                    ),
                                    decoration: _inputDecoration(
                                      hintText: 'student@gmail.com',
                                      prefixIcon: const Icon(
                                        Icons.mail,
                                        color: _darkGreen,
                                        size: 18,
                                      ),
                                    ),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';

                                      if (email.isEmpty) {
                                        return 'Email is required';
                                      }

                                      final isValidEmail = RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      ).hasMatch(email);

                                      if (!isValidEmail) {
                                        return 'Enter a valid email';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 13),

                                  // Password label
                                  const Text(
                                    'PASSWORD',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontSize: 12,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(height: 7),

                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _hidePassword,
                                    keyboardType: TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.done,
                                    autocorrect: false,
                                    enableSuggestions: false,

                                    maxLength: 12,

                                    maxLengthEnforcement:
                                        MaxLengthEnforcement.enforced,

                                    buildCounter:
                                        (
                                          BuildContext context, {
                                          required int currentLength,
                                          required bool isFocused,
                                          required int? maxLength,
                                        }) {
                                          return null;
                                        },

                                    onFieldSubmitted: (_) {
                                      if (!authProvider.isLoading) {
                                        _handleLogin();
                                      }
                                    },

                                    style: const TextStyle(
                                      color: _textColor,
                                      fontSize: 15,
                                      letterSpacing: 1,
                                    ),

                                    decoration: _inputDecoration(
                                      hintText: '********',
                                      prefixIcon: const Icon(
                                        Icons.lock,
                                        color: _darkGreen,
                                        size: 18,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _hidePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: _togglePasswordVisibility,
                                        icon: Icon(
                                          _hidePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: _mutedColor,
                                          size: 21,
                                        ),
                                      ),
                                    ),

                                    validator: (value) {
                                      final password = value ?? '';

                                      if (password.isEmpty) {
                                        return 'Password is required';
                                      }

                                      if (password.length < 8) {
                                        return 'Minimum 8 characters required';
                                      }

                                      if (password.length > 12) {
                                        return 'Maximum 12 characters allowed';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 7),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : _handleForgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: _orange,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 5,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 27),

                                  // Login button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: FilledButton(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : _handleLogin,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _buttonGreen,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: _buttonGreen
                                            .withValues(alpha: 0.55),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: authProvider.isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
