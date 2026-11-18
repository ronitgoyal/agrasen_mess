import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  /// Student room number comes from the Student Dashboard.
  /// Staff/Admin can open this screen without providing it.
  final String? roomNumber;

  const ProfileScreen({
    super.key,
    this.roomNumber,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ---------------------------------------------------------------------------
  // FIGMA COLORS
  // ---------------------------------------------------------------------------

  static const Color _background = Color(0xFFF8FBF9);
  static const Color _green = Color(0xFF1A6E3D);
  static const Color _roleGreen = Color(0xFF298C4A);
  static const Color _orange = Color(0xFFFF7D33);
  static const Color _avatarBackground = Color(0xFFFFF3E9);
  static const Color _text = Color(0xFF18251E);
  static const Color _muted = Color(0xFF637369);

  bool _isLoggingOut = false;

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _formatRole(String role) {
    if (role.isEmpty) return 'User';

    return role
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}'
                  '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool _isStudent(String role) {
    return role.trim().toLowerCase() == 'student';
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.logout_rounded,
            color: _orange,
            size: 42,
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _muted,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted || _isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await context.read<AuthProvider>().logout();

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not log out. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(
          child: CircularProgressIndicator(
            color: _roleGreen,
          ),
        ),
      );
    }

    final String role = _formatRole(user.role);
    final bool isStudent = _isStudent(user.role);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            /*
             * Figma reference width = 390px.
             *
             * Phone:
             * Uses available screen width.
             *
             * Tablet / large screen:
             * Content is capped at 520px and centered,
             * so the Figma proportions are preserved.
             */

            final double contentWidth =
                constraints.maxWidth > 600
                    ? 520
                    : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    _buildHeader(),

                    Expanded(
  child: SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      22,
      20,
      22,
      20,
    ),
    child: Column(
      children: [
        _ProfileIdentity(
          name: user.name,
          role: role,
          initials: _initials(user.name),
        ),

        const SizedBox(height: 34),

        _InformationCard(
          label: 'FULL NAME',
          value: user.name,
        ),

        if (isStudent) ...[
          const SizedBox(height: 14),
          _InformationCard(
            label: 'ROOM NO.',
            value: widget.roomNumber ?? '',
          ),
        ],

        const SizedBox(height: 14),

        _InformationCard(
          label: 'EMAIL',
          value: user.email,
        ),

        const SizedBox(height: 14),

        _InformationCard(
          label: 'MOBILE NO.',
          value: user.phoneNumber ?? '',
        ),

        const SizedBox(height: 20),
      ],
    ),
  ),
),

// --------------------------------------------------
// FIXED LOGOUT BUTTON AT BOTTOM
// --------------------------------------------------

Padding(
  padding: const EdgeInsets.fromLTRB(
    22,
    8,
    22,
    18,
  ),
  child: SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: _background,
        foregroundColor: _orange,
        disabledBackgroundColor: _background,
        disabledForegroundColor: _orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed:
          _isLoggingOut ? null : _confirmLogout,
      child: _isLoggingOut
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _orange,
              ),
            )
          : const Text(
              'Logout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  ),
),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        22,
        6,
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(30),
                onTap: () {
                  Navigator.of(context).maybePop();
                },
                child: const SizedBox(
                  width: 34,
                  height: 48,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _green,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            const Expanded(
              child: Text(
                'My Profile',
                style: TextStyle(
                  color: _text,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PROFILE IDENTITY
// =============================================================================

class _ProfileIdentity extends StatelessWidget {
  final String name;
  final String role;
  final String initials;

  const _ProfileIdentity({
    required this.name,
    required this.role,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---------------------------------------------------------------------
        // FIGMA AVATAR
        // Outer circle = 100px
        // Inner circle = 54px
        // ---------------------------------------------------------------------

        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color:
                _ProfileScreenState._avatarBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: _ProfileScreenState._orange,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // NAME
        // ---------------------------------------------------------------------

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileScreenState._text,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: 7),

        // ---------------------------------------------------------------------
        // ROLE
        // ---------------------------------------------------------------------

        Text(
          role,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color:
                _ProfileScreenState._roleGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// INFORMATION CARD
// =============================================================================

class _InformationCard extends StatelessWidget {
  final String label;
  final String value;

  const _InformationCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final String displayValue =
        value.trim().isEmpty
            ? 'Not available'
            : value.trim();

    return Container(
      width: double.infinity,

      // Figma card height = 58px.
      // minHeight allows longer content to grow rather than overflow.
      constraints: const BoxConstraints(
        minHeight: 58,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 9,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A1A12),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          // -------------------------------------------------------------------
          // LABEL
          // -------------------------------------------------------------------

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  _ProfileScreenState._muted,
              fontSize: 9,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          // -------------------------------------------------------------------
          // VALUE
          // -------------------------------------------------------------------

          Text(
            displayValue,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  _ProfileScreenState._text,
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}