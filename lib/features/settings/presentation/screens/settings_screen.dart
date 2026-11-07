import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_clean_architecture/app/router/routes.dart';
import 'package:riverpod_clean_architecture/core/base/base_screen.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/l10n/locale_notifier.dart';
import 'package:riverpod_clean_architecture/core/theme/app_values.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_network_image.dart';
import 'package:riverpod_clean_architecture/features/settings/presentation/notifiers/settings_notifier.dart';

class SettingsScreen extends BaseScreen {
  const SettingsScreen({super.key});

  static const _languageNames = {'en': 'English', 'bn': 'বাংলা'};

  @override
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) =>
      AppBar(title: Text(context.l10n.settingsTitle));

  @override
  Widget body(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = currentUser(ref);
    final current = Localizations.localeOf(context).languageCode;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppValues.padding),
      children: [
        if (user != null)
          ListTile(
            leading: AppAvatar(url: user.imageUrl, name: user.fullName),
            title: Text(user.fullName, style: context.textStyles.title),
            subtitle: Text(user.email, style: context.textStyles.caption),
          )
        else
          ListTile(
            leading: const Icon(Icons.login),
            title: Text(l10n.loginButton),
            onTap: () => LoginRoute(from: const SettingsRoute().location).go(context),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.settingsLanguage),
          trailing: DropdownButton<String>(
            value: current,
            underline: const SizedBox.shrink(),
            items: [
              for (final locale in LocaleNotifier.supported)
                DropdownMenuItem(
                  value: locale.languageCode,
                  child: Text(_languageNames[locale.languageCode] ?? locale.languageCode),
                ),
            ],
            onChanged: (code) {
              if (code != null) ref.read(localeProvider.notifier).setLocale(Locale(code));
            },
          ),
        ),
        if (user != null)
          ListTile(
            leading: Icon(Icons.logout, color: context.colors.error),
            title: Text(l10n.settingsLogout, style: TextStyle(color: context.colors.error)),
            onTap: () => _confirmLogout(context, ref),
          ),
        const Divider(),
        ListTile(
          title: Text(
            l10n.settingsEnvironment(buildConfig.environment.name),
            style: context.textStyles.caption,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsLogout),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await ref.read(settingsProvider.notifier).logout();
  }
}
