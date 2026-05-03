import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../theme.dart';
import 'onboarding_screen.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Not logged in';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Symbols.menu, color: AppColors.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: AppColors.onSurface),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          // Profile Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer,
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuC5bzyJvs1dPbbDGhnGMc8kehdF_lk8bt8PikfStYWkwP4hkilIgY5ahnnc8iZrvonFh1ra3O5VXrKmUTV_LXQ0MO2nWpno1gs87lraETkG6n5gW6oeRXFFr1yD9GfZO3Hffg5cSA6_NtR9WDL3oss8WpLiVtAL4HqLE94TFUMETAgZ1-APnTxlJZ0s0JwA0hjK6jNZyq1oH8rc0ldCk1dTP43UuCkvB7oOvTLyDjowT87qwjJkAJxdT8wDKaOJrb-C2X3mtTokLcA',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explorer Profile',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Account Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'ACCOUNT',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(
              Symbols.mail,
              color: AppColors.onSurfaceVariant,
            ),
            title: const Text('Email Address'),
            subtitle: Text(email),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(
              Symbols.lock,
              color: AppColors.onSurfaceVariant,
            ),
            title: const Text('Change Password'),
            trailing: const Icon(
              Symbols.chevron_right,
              color: AppColors.outline,
            ),
            onTap: () {}, // Placeholder
          ),

          const Divider(),

          // App Settings Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'APP',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(
              Symbols.dark_mode,
              color: AppColors.onSurfaceVariant,
            ),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: false,
              onChanged: (val) {}, // Placeholder
              activeThumbColor: AppColors.primary,
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(
              Symbols.notifications,
              color: AppColors.onSurfaceVariant,
            ),
            title: const Text('Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (val) {}, // Placeholder
              activeThumbColor: AppColors.primary,
            ),
          ),

          const Divider(),

          // About Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'ABOUT',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(Symbols.info, color: AppColors.onSurfaceVariant),
            title: Text('App Version'),
            subtitle: Text('1.0.0 (Build 42)'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
