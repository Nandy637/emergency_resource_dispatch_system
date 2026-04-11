// ============================================================
// screen: role_selector_screen.dart
// Entry point – citizen selects their role (Citizen/Responder).
// Routes to HomeScreen (citizen SOS) or ResponderDashboard.
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'user/home_screen.dart';
import 'responder/responder_dashboard.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── Logo + title ─────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.15),
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: AppTheme.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SafeCall SOS',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.onSurface,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Emergency Resource Dispatch System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 50),
              const Text(
                'Select your role to continue',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // ── Citizen card ─────────────────────────────
              _RoleCard(
                emoji: '🆘',
                title: 'I Need Help',
                subtitle: 'Citizen SOS – send emergency alert',
                color: AppTheme.primary,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // ── Responder card ───────────────────────────
              _RoleCard(
                emoji: '🚑',
                title: 'I Am a Responder',
                subtitle: 'Ambulance • Fire • Police dashboard',
                color: AppTheme.info,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ResponderDashboard()),
                ),
              ),

              const Spacer(),
              const Text(
                'Emergency services available 24/7',
                style: TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role card widget ──────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
