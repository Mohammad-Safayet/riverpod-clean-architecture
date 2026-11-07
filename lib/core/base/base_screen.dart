import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_clean_architecture/core/exceptions/app_exception_l10n.dart';
import 'package:riverpod_clean_architecture/core/extensions/context_extensions.dart';
import 'package:riverpod_clean_architecture/core/session/session_notifier.dart';
import 'package:riverpod_clean_architecture/core/session/session_user.dart';
import 'package:riverpod_clean_architecture/core/utils/app_logger.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_error_view.dart';
import 'package:riverpod_clean_architecture/core/widgets/app_loading.dart';
import 'package:riverpod_clean_architecture/flavors/build_config.dart';

/// Every screen extends [BaseScreen] (or [BaseStatefulScreen] when it needs
/// controllers / initState). Change something here and every screen follows.
///
/// ```dart
/// class ProductsScreen extends BaseScreen {
///   const ProductsScreen({super.key});
///
///   @override
///   PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) =>
///       AppBar(title: Text(context.l10n.productsTitle));
///
///   @override
///   Widget body(BuildContext context, WidgetRef ref) =>
///       asyncBody(ref.watch(productDetailProvider(id)), data: (p) => ...);
/// }
/// ```
///
/// App-wide UI that must appear once (blocking loader, snackbars, offline banner)
/// lives in `AppOverlayHost`, not here, so nested screens don't duplicate it.
abstract class BaseScreen extends ConsumerWidget with BaseScreenMixin {
  const BaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => buildScreen(context, ref);
}

/// [BaseScreen] for screens that own controllers (text, scroll, animation).
///
/// ```dart
/// class LoginScreen extends BaseStatefulScreen {
///   const LoginScreen({super.key});
///   @override
///   BaseScreenState<LoginScreen> createState() => _LoginScreenState();
/// }
///
/// class _LoginScreenState extends BaseScreenState<LoginScreen> {
///   final _username = TextEditingController();
///   @override
///   Widget body(BuildContext context, WidgetRef ref) => ...;
/// }
/// ```
abstract class BaseStatefulScreen extends ConsumerStatefulWidget {
  const BaseStatefulScreen({super.key});

  @override
  BaseScreenState<BaseStatefulScreen> createState();
}

abstract class BaseScreenState<T extends BaseStatefulScreen> extends ConsumerState<T>
    with BaseScreenMixin {
  @override
  Widget build(BuildContext context) => buildScreen(context, ref);
}

/// Shared by [BaseScreen] and [BaseScreenState]: the page skeleton, its hooks and
/// the data every screen can reach.
mixin BaseScreenMixin {
  // ---- Hooks: override what the screen needs ------------------------------

  Widget body(BuildContext context, WidgetRef ref);

  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) => null;

  Widget? floatingActionButton(BuildContext context, WidgetRef ref) => null;

  Widget? bottomNavigationBar(BuildContext context, WidgetRef ref) => null;

  Widget? drawer(BuildContext context, WidgetRef ref) => null;

  /// Defaults to `AppColors.pageBackground`.
  Color? backgroundColor(BuildContext context) => null;

  /// Status bar look. Defaults to dark icons on the page background.
  SystemUiOverlayStyle systemOverlayStyle(BuildContext context) =>
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

  bool get useSafeArea => true;

  bool get resizeToAvoidBottomInset => true;

  // ---- Shared data: available in every screen -----------------------------

  Logger get logger => appLogger;

  BuildConfig get buildConfig => BuildConfig.instance;

  /// Signed-in user, or null. Rebuilds the screen when it changes.
  SessionUser? currentUser(WidgetRef ref) => ref.watch(sessionProvider.select((s) => s.user));

  // `context.l10n`, `context.colors`, `context.textStyles` come from ContextX.

  // ---- Helpers ------------------------------------------------------------

  /// Standard loading / error / data rendering for page data. The loading and
  /// error widgets are defined once here for every screen.
  Widget asyncBody<D>(
    AsyncValue<D> value, {
    required Widget Function(D data) data,
    VoidCallback? onRetry,
  }) {
    // Keeps showing old data while refreshing; a retry after an error shows loading.
    if (value.hasValue) return data(value.requireValue);
    if (value.isLoading) return const AppLoading();
    if (value.error case final error?) {
      return AppErrorView(exception: asAppException(error), onRetry: onRetry);
    }
    return const AppLoading();
  }

  // ---- Skeleton -----------------------------------------------------------

  Widget buildScreen(BuildContext context, WidgetRef ref) {
    final content = body(context, ref);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle(context),
      child: Scaffold(
        backgroundColor: backgroundColor(context) ?? context.colors.pageBackground,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: appBar(context, ref),
        floatingActionButton: floatingActionButton(context, ref),
        bottomNavigationBar: bottomNavigationBar(context, ref),
        drawer: drawer(context, ref),
        body: useSafeArea ? SafeArea(child: content) : content,
      ),
    );
  }
}
