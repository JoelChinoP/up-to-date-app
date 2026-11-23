import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Contenedor de lectura con ancho máximo y márgenes adaptativos.
class ContentFrame extends StatelessWidget {
  const ContentFrame({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding,
    this.horizontalPadding,
    this.verticalPadding = 24,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final double? horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 900
            ? 32.0
            : constraints.maxWidth >= 600
            ? 24.0
            : 16.0;
        final resolved =
            padding ??
            EdgeInsets.symmetric(
              horizontal: horizontalPadding ?? horizontal,
              vertical: verticalPadding,
            );
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: resolved, child: child),
          ),
        );
      },
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.compactTrailing = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool compactTrailing;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: mutedInk),
            ),
          ),
        ],
      ],
    );
    if (trailing == null) return text;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560 && !compactTrailing) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 12), trailing!],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: text),
            const SizedBox(width: 16),
            trailing!,
          ],
        );
      },
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 12,
              letterSpacing: 0.8,
              color: mutedInk,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class MoSurface extends StatelessWidget {
  const MoSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.border = true,
    this.fill = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool border;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill ? softSurface : paper,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: softDivider) : null,
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: mutedInk),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedInk),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.text, {
    super.key,
    this.style,
    this.align = TextAlign.end,
  });

  final String text;
  final TextStyle? style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

void showMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
