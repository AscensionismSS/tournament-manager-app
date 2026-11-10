import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'app_search_bar.dart';

/// Opção para o [AppSelectBox].
class AppSelectOption<T> {
  final T? value;
  final String label;
  final IconData? icon;
  final Widget Function(BuildContext context, bool isSelected)? iconBuilder;
  final Widget? iconWidget;

  const AppSelectOption({
    required this.value,
    required this.label,
    this.icon,
    this.iconBuilder,
    this.iconWidget,
  });
}

/// Select Box customizado padronizado com o Design System da aplicação.
/// - Abre diretamente embaixo do campo disparador.
/// - Suporta busca/digitação em tempo real ("Searchable").
/// - Exibe no máximo 5 itens simultâneos e ativa rolagem suave para os demais.
/// - Cores de superfície, bordas e tipografia alinhadas com [AppColors].
class AppSelectBox<T> extends StatefulWidget {
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? placeholder;
  final IconData? prefixIcon;
  final double? width;
  final double? height;
  final bool? isFiltered;
  final bool isHighlighted;
  final Color? accentColor;
  final bool showSelectedIcon;
  final bool showSearch;
  final double? dropdownMaxHeight;

  const AppSelectBox({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
    this.prefixIcon,
    this.width,
    this.height,
    this.isFiltered,
    this.isHighlighted = false,
    this.accentColor,
    this.showSelectedIcon = false,
    this.showSearch = false,
    this.dropdownMaxHeight,
  });

  @override
  State<AppSelectBox<T>> createState() => _AppSelectBoxState<T>();
}

class _AppSelectBoxState<T> extends State<AppSelectBox<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isOpen = false;

  @override
  void didUpdateWidget(covariant AppSelectBox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (_isOpen) {
        _closeDropdown();
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown(BuildContext context, double effectiveWidth, Color effectiveAccentColor) {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown(context, effectiveWidth, effectiveAccentColor);
    }
  }

  void _openDropdown(BuildContext context, double effectiveWidth, Color effectiveAccentColor) {
    _removeOverlay();
    _searchQuery = '';
    _searchController.clear();

    _overlayEntry = _createOverlayEntry(effectiveWidth, effectiveAccentColor);
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _removeOverlay();
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  List<AppSelectOption<T>> _getUniqueOptions() {
    final uniqueOptions = <AppSelectOption<T>>[];
    final seenValues = <T?>{};
    for (final opt in widget.options) {
      if (seenValues.add(opt.value)) {
        uniqueOptions.add(opt);
      }
    }
    return uniqueOptions;
  }

  OverlayEntry _createOverlayEntry(double effectiveWidth, Color effectiveAccentColor) {
    return OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final uniqueOptions = _getUniqueOptions();
            final showSearch = widget.showSearch && uniqueOptions.length >= 5;
            final query = _searchQuery.toLowerCase().trim();
            // A opção "Todos/Todas" (value == null) é fixa: nunca é filtrada pela busca.
            final pinned = uniqueOptions.where((opt) => opt.value == null).toList();
            final searchable = uniqueOptions.where((opt) => opt.value != null).toList();
            final matches = (query.isEmpty || !showSearch)
                ? searchable
                : searchable.where((opt) => opt.label.toLowerCase().contains(query)).toList();
            final filtered = [...pinned, ...matches];
            final showNoResults = matches.isEmpty && query.isNotEmpty;

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _closeDropdown,
                  ),
                ),
                Positioned(
                  width: effectiveWidth,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset(0, (widget.height ?? 44) + 4),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: effectiveWidth,
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: effectiveAccentColor.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: effectiveAccentColor.withValues(alpha: 0.12),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showSearch) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: AppSearchBar(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  isCompact: true,
                                  autofocus: true,
                                  debounceDuration: Duration.zero,
                                  hintText: 'Filtrar opções...',
                                  cursorColor: effectiveAccentColor,
                                  onSearch: (text) {
                                    setOverlayState(() {
                                      _searchQuery = text;
                                    });
                                  },
                                  onClear: () {
                                    setOverlayState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                              ),
                              Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                            ],
                            ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: widget.dropdownMaxHeight ?? 320),
                              child: (filtered.isEmpty && !showNoResults)
                                  ? Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Nenhuma opção disponível',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: filtered.length + (showNoResults ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index < filtered.length) {
                                          final opt = filtered[index];
                                          final isSelected = opt.value == widget.value;

                                          return InkWell(
                                            onTap: () {
                                              widget.onChanged(opt.value);
                                              _closeDropdown();
                                            },
                                            child: Container(
                                              height: 40,
                                              padding: const EdgeInsets.symmetric(horizontal: 14),
                                              color: isSelected
                                                  ? effectiveAccentColor.withValues(alpha: 0.12)
                                                  : Colors.transparent,
                                              child: Row(
                                                children: [
                                                  if (opt.iconBuilder != null) ...[
                                                    opt.iconBuilder!(context, isSelected),
                                                    const SizedBox(width: 10),
                                                  ] else if (opt.iconWidget != null) ...[
                                                    opt.iconWidget!,
                                                    const SizedBox(width: 10),
                                                  ] else if (opt.icon != null) ...[
                                                    Icon(
                                                      opt.icon,
                                                      size: 16,
                                                      color: isSelected
                                                          ? effectiveAccentColor
                                                          : AppColors.onSurface.withValues(alpha: 0.6),
                                                    ),
                                                    const SizedBox(width: 10),
                                                  ],
                                                  Expanded(
                                                    child: Text(
                                                      opt.label,
                                                      style: TextStyle(
                                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                                        color: isSelected ? effectiveAccentColor : AppColors.onBackground,
                                                        letterSpacing: 0.3,
                                                        fontSize: 12.5,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isSelected) ...[
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.check_rounded,
                                                      size: 16,
                                                      color: effectiveAccentColor,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Container(
                                            height: 40,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                            child: Text(
                                              'Nenhum resultado encontrado',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.onSurface.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isFlexible = widget.width == double.infinity;
        final parentWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 220.0;
        final effectiveWidth = isFlexible
            ? parentWidth
            : (widget.width != null ? widget.width! : parentWidth.clamp(160.0, 360.0));

        final hasActiveFilter = widget.isFiltered ?? false;
        final effectiveAccentColor = widget.accentColor ?? colorScheme.primary;
        final showHighlight = widget.isHighlighted || hasActiveFilter || _isOpen;

        final uniqueOptions = _getUniqueOptions();
        final selectedOption = uniqueOptions.firstWhere(
          (opt) => opt.value == widget.value,
          orElse: () => (uniqueOptions.isNotEmpty
              ? uniqueOptions.first
              : AppSelectOption<T>(value: null, label: widget.placeholder ?? '')),
        );

        final effectiveLeadingWidget = widget.showSelectedIcon
            ? (selectedOption.iconBuilder != null
                ? selectedOption.iconBuilder!(context, showHighlight)
                : selectedOption.iconWidget)
            : null;

        final effectivePrefixIcon = widget.showSelectedIcon
            ? (selectedOption.icon ?? widget.prefixIcon)
            : widget.prefixIcon;

        return CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown(context, effectiveWidth, effectiveAccentColor),
            child: Container(
              width: isFlexible ? double.infinity : effectiveWidth,
              height: widget.height ?? 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: showHighlight ? AppColors.cardSurface : AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: showHighlight
                      ? effectiveAccentColor.withValues(alpha: 0.75)
                      : AppColors.border,
                  width: showHighlight ? 1.4 : 1.0,
                ),
                boxShadow: [
                  if (showHighlight)
                    BoxShadow(
                      color: effectiveAccentColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                ],
              ),
              child: Row(
                children: [
                  if (effectiveLeadingWidget != null) ...[
                    effectiveLeadingWidget,
                    const SizedBox(width: 10),
                  ] else if (effectivePrefixIcon != null) ...[
                    Icon(
                      effectivePrefixIcon,
                      size: 16,
                      color: showHighlight
                          ? effectiveAccentColor
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      selectedOption.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: showHighlight ? Colors.white : colorScheme.onSurface,
                        fontWeight: showHighlight ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0.4,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: showHighlight
                          ? effectiveAccentColor
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
