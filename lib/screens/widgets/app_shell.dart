import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/branding.dart';

enum _BackdropTone { surface, auth }

class AppScrollableBody extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const AppScrollableBody({
    super.key,
    required this.children,
    this.maxWidth = 1080,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return _BrandedBackdrop.surface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 720 ? 24.0 : 16.0;
          return ListView(
            padding:
                padding ?? EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AppPageIntro extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final Widget? supporting;
  final Widget? trailing;

  const AppPageIntro({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.supporting,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactScreen = screenWidth < 480;
    return Container(
      padding: EdgeInsets.all(compactScreen ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -28,
            child: _GlowBlob(
              size: 180,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -56,
            left: -30,
            child: _GlowBlob(
              size: 140,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 820;
              final compact = constraints.maxWidth < 540;
              final titleFontSize = compact ? 22.0 : 30.0;
              final leading = Container(
                width: compact ? 54 : 62,
                height: compact ? 54 : 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(compact ? 16 : 18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(icon, size: compact ? 24 : 28, color: Colors.white),
              );

              final headerText = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    AppIntroTag(label: badge!),
                    SizedBox(height: compact ? 10 : 14),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: compact ? 13 : 14,
                      height: 1.55,
                    ),
                  ),
                ],
              );

              final trailingBlock = trailing == null
                  ? null
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: stacked ? constraints.maxWidth : 320,
                        maxWidth: stacked ? constraints.maxWidth : 520,
                      ),
                      child: AppIntroPanel(child: trailing!),
                    );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leading,
                        SizedBox(width: compact ? 12 : 16),
                        Expanded(child: headerText),
                      ],
                    ),
                    if (supporting != null) ...[
                      const SizedBox(height: 16),
                      supporting!,
                    ],
                    if (trailingBlock != null) ...[
                      SizedBox(height: compact ? 14 : 18),
                      trailingBlock,
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leading,
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              headerText,
                              if (supporting != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 18),
                                  child: supporting!,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailingBlock != null) ...[
                    const SizedBox(width: 20),
                    Flexible(child: trailingBlock),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AppIntroPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppIntroPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
          : padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppIntroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool emphasized;

  const AppIntroActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    final disabled = onPressed == null;
    final foreground = disabled
        ? Colors.white.withValues(alpha: 0.55)
        : destructive
        ? const Color(0xFFFFE2E2)
        : emphasized
        ? AppTheme.primaryDark
        : Colors.white;
    final background = destructive
        ? const Color(0xFF7F1D1D).withValues(alpha: 0.42)
        : emphasized
        ? Colors.white
        : Colors.white.withValues(alpha: 0.12);
    final border = destructive
        ? const Color(0xFFFCA5A5).withValues(alpha: 0.42)
        : emphasized
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.16);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 11 : 13,
              vertical: compact ? 9 : 11,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 22 : 26,
                  height: compact ? 22 : 26,
                  decoration: BoxDecoration(
                    color: emphasized
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : Colors.white.withValues(
                            alpha: destructive ? 0.08 : 0.1,
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: compact ? 14 : 16, color: foreground),
                ),
                SizedBox(width: compact ? 6 : 8),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppIntroSectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;

  const AppIntroSectionLabel({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: compact ? 12 : 14,
            color: Colors.white.withValues(alpha: 0.76),
          ),
          SizedBox(width: compact ? 4 : 6),
        ],
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class AppIntroStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color accentColor;

  const AppIntroStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 112 : 134,
        maxWidth: compact ? 152 : 180,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 11 : 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: compact ? 24 : 30,
              height: compact ? 24 : 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: compact ? 13 : 16, color: Colors.white),
            ),
            SizedBox(height: compact ? 8 : 12),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              color: accentColor,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class AppIntroTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  const AppIntroTag({
    super.key,
    required this.label,
    this.icon,
    this.foregroundColor = Colors.white,
    this.backgroundColor = const Color(0x24FFFFFF),
    this.borderColor = const Color(0x2EFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: foregroundColor),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AppActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color? textColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const AppActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.primary,
    this.textColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  });

  @override
  Widget build(BuildContext context) {
    final foreground = textColor ?? color;
    final background = backgroundColor ?? Colors.white.withValues(alpha: 0.78);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: foreground),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppSelectablePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const AppSelectablePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? color : AppTheme.textMedium;
    final background = selected
        ? color.withValues(alpha: 0.12)
        : const Color(0xFFF8FBFD);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppSectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const AppSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themedTrailing = trailing == null
        ? null
        : Theme(
            data: Theme.of(context).copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style:
                    (Theme.of(context).filledButtonTheme.style ??
                            const ButtonStyle())
                        .copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                            Size(0, 48),
                          ),
                        ),
              ),
            ),
            child: trailing!,
          );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stackedHeader =
                  themedTrailing != null && constraints.maxWidth < 860;
              final headerIcon = Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.14),
                      AppTheme.secondary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 22),
              );

              final headerText = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              );

              if (stackedHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerIcon,
                        const SizedBox(width: 14),
                        Expanded(child: headerText),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: themedTrailing,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerIcon,
                  const SizedBox(width: 14),
                  Expanded(child: headerText),
                  if (themedTrailing != null) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: themedTrailing,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Divider(color: AppTheme.border.withValues(alpha: 0.85)),
          const SizedBox(height: 18),
          ..._withSpacing(children),
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items) {
    if (items.isEmpty) return const [];
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        result.add(const SizedBox(height: 16));
      }
      result.add(items[i]);
    }
    return result;
  }
}

class AdaptiveFieldRow extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;
  final double spacing;
  final double minItemWidth;

  const AdaptiveFieldRow({
    super.key,
    required this.children,
    this.maxColumns = 2,
    this.spacing = 16,
    this.minItemWidth = 240,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = math.min(maxColumns, children.length);
        while (columns > 1) {
          final itemWidth = (width - ((columns - 1) * spacing)) / columns;
          if (itemWidth >= minItemWidth) {
            break;
          }
          columns--;
        }

        final itemWidth = columns <= 1
            ? width
            : (width - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class AppDatePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool hasError;

  const AppDatePickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.placeholder = 'Seçilmedi',
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.textMedium,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasError ? const Color(0xFFEF4444) : AppTheme.border,
            ),
          ),
        ),
        child: Text(
          value ?? placeholder,
          style: TextStyle(
            fontSize: 14,
            color: value == null ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

SnackBar buildErrorSnackBar(String message) => SnackBar(
  content: Text(message),
  backgroundColor: const Color(0xFFEF4444),
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

class AuthHighlight {
  final IconData icon;
  final String title;
  final String description;

  const AuthHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class AuthScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String formTitle;
  final String formSubtitle;
  final List<AuthHighlight> highlights;
  final Widget child;
  final Widget footer;
  final bool showIntro;

  const AuthScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.formTitle,
    required this.formSubtitle,
    required this.highlights,
    required this.child,
    required this.footer,
    this.showIntro = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SizedBox.expand(
        child: _BrandedBackdrop.auth(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final padding = constraints.maxWidth >= 720 ? 28.0 : 18.0;
                final minHeight = (constraints.maxHeight - (padding * 2)).clamp(
                  0.0,
                  double.infinity,
                );

                final content = !showIntro
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _AuthCard(
                            title: formTitle,
                            subtitle: formSubtitle,
                            footer: footer,
                            child: child,
                          ),
                        ),
                      )
                    : wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _AuthIntro(
                              eyebrow: eyebrow,
                              title: title,
                              subtitle: subtitle,
                              highlights: highlights,
                            ),
                          ),
                          const SizedBox(width: 32),
                          SizedBox(
                            width: 440,
                            child: _AuthCard(
                              title: formTitle,
                              subtitle: formSubtitle,
                              footer: footer,
                              child: child,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _AuthIntro(
                            eyebrow: eyebrow,
                            title: title,
                            subtitle: subtitle,
                            highlights: highlights,
                            compact: true,
                          ),
                          const SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: _AuthCard(
                              title: formTitle,
                              subtitle: formSubtitle,
                              footer: footer,
                              child: child,
                            ),
                          ),
                        ],
                      );

                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: showIntro
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: content,
                            ),
                          )
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: content,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandedBackdrop extends StatelessWidget {
  final Widget child;
  final _BackdropTone tone;

  const _BrandedBackdrop.surface({required this.child})
    : tone = _BackdropTone.surface;

  const _BrandedBackdrop.auth({required this.child})
    : tone = _BackdropTone.auth;

  @override
  Widget build(BuildContext context) {
    final isAuth = tone == _BackdropTone.auth;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAuth
              ? const [
                  AppTheme.primaryDark,
                  AppTheme.primary,
                  AppTheme.secondary,
                ]
              : const [Color(0xFFEAF1FA), Color(0xFFF5FAF8), Color(0xFFE8F4F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -70,
            child: _GlowBlob(
              size: isAuth ? 280 : 260,
              color: isAuth
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _GlowBlob(
              size: isAuth ? 240 : 230,
              color: isAuth
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.secondary.withValues(alpha: 0.07),
            ),
          ),
          Positioned.fill(
            child: _BrandWatermarkPattern(opacityScale: isAuth ? 1 : 0.52),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuthIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<AuthHighlight> highlights;
  final bool compact;

  const _AuthIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.highlights,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 64.0 : 78.0;
    return Padding(
      padding: EdgeInsets.only(right: compact ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(Branding.logoAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            Branding.companyName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              eyebrow,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 28 : 40,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: compact ? 14 : 16,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          ...highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          child,
          const SizedBox(height: 20),
          footer,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BrandWatermarkPattern extends StatelessWidget {
  final double opacityScale;

  const _BrandWatermarkPattern({required this.opacityScale});

  static const _specs = <_WatermarkSpec>[
    _WatermarkSpec(x: -0.1, y: 0.02, scale: 0.28, angle: -0.22, opacity: 0.18),
    _WatermarkSpec(x: 0.1, y: 0.14, scale: 0.18, angle: 0.1, opacity: 0.14),
    _WatermarkSpec(x: 0.28, y: 0.06, scale: 0.16, angle: -0.18, opacity: 0.12),
    _WatermarkSpec(x: 0.5, y: 0.14, scale: 0.22, angle: 0.22, opacity: 0.16),
    _WatermarkSpec(x: 0.76, y: 0.02, scale: 0.26, angle: -0.14, opacity: 0.17),
    _WatermarkSpec(x: 0.84, y: 0.24, scale: 0.18, angle: 0.26, opacity: 0.13),
    _WatermarkSpec(x: -0.02, y: 0.34, scale: 0.22, angle: 0.14, opacity: 0.15),
    _WatermarkSpec(x: 0.2, y: 0.3, scale: 0.16, angle: -0.1, opacity: 0.12),
    _WatermarkSpec(x: 0.46, y: 0.38, scale: 0.28, angle: -0.2, opacity: 0.18),
    _WatermarkSpec(x: 0.7, y: 0.36, scale: 0.2, angle: 0.16, opacity: 0.14),
    _WatermarkSpec(x: 0.06, y: 0.58, scale: 0.24, angle: -0.16, opacity: 0.16),
    _WatermarkSpec(x: 0.34, y: 0.6, scale: 0.18, angle: 0.12, opacity: 0.13),
    _WatermarkSpec(x: 0.58, y: 0.56, scale: 0.3, angle: -0.18, opacity: 0.19),
    _WatermarkSpec(x: 0.8, y: 0.64, scale: 0.2, angle: -0.08, opacity: 0.14),
    _WatermarkSpec(x: -0.04, y: 0.8, scale: 0.28, angle: 0.18, opacity: 0.18),
    _WatermarkSpec(x: 0.24, y: 0.82, scale: 0.16, angle: -0.14, opacity: 0.12),
    _WatermarkSpec(x: 0.5, y: 0.8, scale: 0.22, angle: 0.2, opacity: 0.15),
    _WatermarkSpec(x: 0.76, y: 0.86, scale: 0.24, angle: -0.12, opacity: 0.16),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = math.min(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                for (final spec in _specs)
                  Positioned(
                    left: constraints.maxWidth * spec.x,
                    top: constraints.maxHeight * spec.y,
                    child: Opacity(
                      opacity: spec.opacity * opacityScale,
                      child: Transform.rotate(
                        angle: spec.angle,
                        child: SizedBox(
                          width: base * spec.scale,
                          height: base * spec.scale,
                          child: ClipOval(
                            child: Image.asset(
                              Branding.logoAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WatermarkSpec {
  final double x;
  final double y;
  final double scale;
  final double angle;
  final double opacity;

  const _WatermarkSpec({
    required this.x,
    required this.y,
    required this.scale,
    required this.angle,
    required this.opacity,
  });
}
