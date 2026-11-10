import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Barra de busca moderna e padronizada com debounce de 500ms.
/// Acabamento gamer com contorno fino dourado de prestígio.
/// Gerencia internamente o ciclo de vida do debounce com cancelamento seguro no dispose.
class AppSearchBar extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final ValueChanged<String> onSearch;
  final Duration debounceDuration;
  final bool isLoading;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onClear;
  final bool isCompact;
  final bool autofocus;
  final Color? cursorColor;

  const AppSearchBar({
    super.key,
    this.labelText,
    this.hintText,
    required this.onSearch,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.isLoading = false,
    this.controller,
    this.focusNode,
    this.onClear,
    this.isCompact = false,
    this.autofocus = false,
    this.cursorColor,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  bool _ownsController = false;
  Timer? _debounceTimer;
  String _lastSearchTerm = '';
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _hasText = _controller.text.isNotEmpty;
    _lastSearchTerm = _controller.text.trim();
  }

  void _onChanged(String query) {
    final hasTextNow = query.isNotEmpty;
    if (_hasText != hasTextNow) {
      setState(() {
        _hasText = hasTextNow;
      });
    }

    _debounceTimer?.cancel();
    if (widget.debounceDuration == Duration.zero) {
      final trimmed = query.trim();
      if (trimmed != _lastSearchTerm) {
        _lastSearchTerm = trimmed;
        widget.onSearch(trimmed);
      }
      return;
    }

    _debounceTimer = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      final trimmed = query.trim();
      // Prevenção de buscas repetidas redundantes
      if (trimmed != _lastSearchTerm) {
        _lastSearchTerm = trimmed;
        widget.onSearch(trimmed);
      }
    });
  }

  void _handleClear() {
    _debounceTimer?.cancel();
    _controller.clear();
    setState(() {
      _hasText = false;
    });
    _lastSearchTerm = '';
    widget.onSearch('');
    widget.onClear?.call();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget? suffix;
    if (widget.isLoading) {
      suffix = Padding(
        padding: EdgeInsets.all(widget.isCompact ? 8.0 : 12.0),
        child: SizedBox(
          width: widget.isCompact ? 14 : 18,
          height: widget.isCompact ? 14 : 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: colorScheme.primary,
          ),
        ),
      );
    } else if (_hasText) {
      suffix = IconButton(
        icon: Icon(Icons.close_rounded, size: widget.isCompact ? 14 : 20),
        tooltip: 'Limpar busca',
        color: colorScheme.onSurface.withValues(alpha: widget.isCompact ? 0.6 : 0.7),
        onPressed: _handleClear,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: widget.isCompact ? 28 : 46,
          minHeight: widget.isCompact ? 36 : 46,
        ),
      );
    }

    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      cursorColor: widget.cursorColor,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: widget.isCompact
          ? const TextStyle(fontSize: 12.5, color: AppColors.onBackground)
          : const TextStyle(fontSize: 14.0, color: Colors.white),
      onFieldSubmitted: (value) {
        _debounceTimer?.cancel();
        final trimmed = value.trim();
        _lastSearchTerm = trimmed;
        widget.onSearch(trimmed);
      },
      decoration: InputDecoration(
        isDense: true,
        contentPadding: widget.isCompact
            ? const EdgeInsets.symmetric(horizontal: 0, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: widget.isCompact ? 12.5 : 13.5,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 13.5,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurface.withValues(alpha: widget.isCompact ? 0.65 : 0.7),
          size: widget.isCompact ? 16 : 22,
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: widget.isCompact ? 28 : 46,
          minHeight: widget.isCompact ? 36 : 46,
        ),
        suffixIcon: suffix,
        suffixIconConstraints: BoxConstraints(
          minWidth: widget.isCompact ? 28 : 46,
          minHeight: widget.isCompact ? 36 : 46,
        ),
        filled: true,
        fillColor: AppColors.canvasSurface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isCompact ? 8 : 10),
          borderSide: BorderSide(
            color: AppColors.dotaGold.withValues(alpha: 0.40),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isCompact ? 8 : 10),
          borderSide: const BorderSide(
            color: AppColors.dotaGold,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
