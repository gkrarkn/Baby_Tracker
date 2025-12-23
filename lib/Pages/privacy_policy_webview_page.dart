import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyWebViewPage extends StatefulWidget {
  final String assetPath; // örn: assets/privacy-policy-tr.html
  final String title;

  const PrivacyPolicyWebViewPage({
    super.key,
    required this.assetPath,
    required this.title,
  });

  @override
  State<PrivacyPolicyWebViewPage> createState() =>
      _PrivacyPolicyWebViewPageState();
}

class _PrivacyPolicyWebViewPageState extends State<PrivacyPolicyWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset(widget.assetPath); // ✅ kritik nokta
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
