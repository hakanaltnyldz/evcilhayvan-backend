import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_palette.dart';

/// Tüm ekranların standart wrapper'ı.
///
/// AppBar'ı `AppPalette.appBarDark` rengiyle oluşturur, SystemUI overlay'i
/// doğru ayarlar ve karanlık mod farkı olmaksızın tutarlı görünüm sağlar.
///
/// Kullanım:
/// ```dart
/// AppScaffold(
///   title: 'Ekran Başlığı',
///   body: MyContent(),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.appBarColor,
    this.flexibleSpace,
    this.bottom,
    this.leading,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.centerTitle = false,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final Color? appBarColor;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final barColor = appBarColor ?? AppPalette.appBarDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor ?? AppPalette.background,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        appBar: (title != null || titleWidget != null || actions != null || flexibleSpace != null)
            ? AppBar(
                backgroundColor: barColor,
                foregroundColor: Colors.white,
                centerTitle: centerTitle,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: leading,
                title: titleWidget ??
                    (title != null
                        ? Text(
                            title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          )
                        : null),
                actions: actions,
                flexibleSpace: flexibleSpace,
                bottom: bottom,
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                ),
              )
            : null,
        body: body,
      ),
    );
  }
}
