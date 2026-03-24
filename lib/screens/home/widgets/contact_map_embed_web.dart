import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../core/branding.dart';

class ContactMapEmbed extends StatefulWidget {
  final double height;

  const ContactMapEmbed({super.key, this.height = 320});

  @override
  State<ContactMapEmbed> createState() => _ContactMapEmbedState();
}

class _ContactMapEmbedState extends State<ContactMapEmbed> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'contact-map-${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = Branding.googleMapsEmbedUrl
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..loading = 'lazy';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
