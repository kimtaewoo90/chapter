import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/theme/app_theme.dart';
import '../models/korean_address_result.dart';

/// 카카오(다음) 우편번호 — tykann/kpostal 호스트 HTML + webview_flutter
class KoreanAddressSearchScreen extends StatefulWidget {
  const KoreanAddressSearchScreen({super.key});

  static const _searchUrl =
      'https://tykann.github.io/kpostal/assets/kakao_postcode.html?enableKakao=false';

  @override
  State<KoreanAddressSearchScreen> createState() => _KoreanAddressSearchScreenState();
}

class _KoreanAddressSearchScreenState extends State<KoreanAddressSearchScreen> {
  late final WebViewController _controller;
  var _loading = true;
  var _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'onComplete',
        onMessageReceived: _onAddressMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _loadFailed = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(KoreanAddressSearchScreen._searchUrl));
  }

  void _onAddressMessage(JavaScriptMessage message) {
    try {
      final raw = jsonDecode(message.message);
      if (raw is! Map) return;
      final result = KoreanAddressResult.fromDaumJson(Map<String, dynamic>.from(raw));
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주소를 불러오지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('주소 검색'),
        backgroundColor: AppTheme.paper,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          if (_loadFailed)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '주소 검색 페이지를 열지 못했어요.\n네트워크 연결을 확인해 주세요.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _loadFailed = false;
                        });
                        _controller.loadRequest(Uri.parse(KoreanAddressSearchScreen._searchUrl));
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
