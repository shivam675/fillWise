import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/templates_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();

    Widget buildContent() {
      return switch (navigationProvider.destination) {
        NavSection.chat => const ChatScreen(),
        NavSection.templates => const TemplatesScreen(),
        NavSection.documents => const DocumentsScreen(),
        NavSection.settings => const SettingsScreen(),
      };
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Bar
          Container(
            height: 60,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'AI Template Agent',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // User profile and settings
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle, color: AppColors.textPrimary),
                  color: AppColors.surface,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Text('Profile', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Settings', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthProvider>().logout();
                    } else if (value == 'settings') {
                      navigationProvider.setDestination(NavSection.settings);
                    }
                  },
                ),
              ],
            ),
          ),
          // Main Body
          Expanded(
            child: Row(
              children: [
                // Left Sidebar
                Container(
                  width: 250,
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _NavItem(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        isSelected: navigationProvider.destination == NavSection.chat,
                        onTap: () => navigationProvider.setDestination(NavSection.chat),
                      ),
                      _NavItem(
                        icon: Icons.dashboard_customize_outlined,
                        label: 'Templates',
                        isSelected: navigationProvider.destination == NavSection.templates,
                        onTap: () => navigationProvider.setDestination(NavSection.templates),
                      ),
                      _NavItem(
                        icon: Icons.description_outlined,
                        label: 'Documents',
                        isSelected: navigationProvider.destination == NavSection.documents,
                        onTap: () => navigationProvider.setDestination(NavSection.documents),
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        isSelected: navigationProvider.destination == NavSection.settings,
                        onTap: () => navigationProvider.setDestination(NavSection.settings),
                      ),
                    ],
                  ),
                ),
                // Content Area
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accent.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        hoverColor: AppColors.accent.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(4),
            border: isSelected
                ? Border.all(color: AppColors.accent, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
