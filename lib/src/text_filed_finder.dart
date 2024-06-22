import 'package:flutter/material.dart';

class TextFieldFinder extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;

  TextFieldFinder({
    required this.child,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return _findAndWrapTextField(child);
  }

  Widget _findAndWrapTextField(Widget widget) {
    if (widget is TextField) {
      return TextField(
        focusNode: widget.focusNode ?? focusNode,
        controller: widget.controller,
        decoration: widget.decoration,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        style: widget.style,
        textAlign: widget.textAlign,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        enabled: widget.enabled,
      );
    
    } else if (widget is Column || widget is Row || widget is Stack) {
    // Assuming you're dealing with a layout that can have multiple children
    final children = (widget as MultiChildRenderObjectWidget).children.map(_findAndWrapTextField).toList();
    if (widget is Column) {
      return Column(children: children);
    } else if (widget is Row) {
      return Row(children: children);
    } else if (widget is Stack) {
      return Stack(children: children);
    }
  } else if (widget is Container) {
    // Example for SingleChildRenderObjectWidget
    return Container(child: _findAndWrapTextField(widget.child!));
  } else if (widget is DecoratedBox) {
    // Example for ProxyWidget
    return DecoratedBox(decoration: widget.decoration, child: _findAndWrapTextField(widget.child!));
  } else if (widget is Flexible) {
    // Example for ParentDataWidget
    return Flexible(child: _findAndWrapTextField(widget.child));
  }
  return widget;
  }}
