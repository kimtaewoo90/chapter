import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/theme/app_theme.dart';
import '../models/korean_address_result.dart';

/// 카카오(다음) 우편번호 — tykann/kpostal 호스트 HTML + webview_flutter
class KoreanAddressSearchScreen extends StatefulWidget {
  const KoreanAddressSearchScreen({super.key, this.inSheet = false});

  final bool inSheet;

  static const _searchUrl =
      'https://tykann.github.io/kpostal/assets/kakao_postcode.html?enableKakao=false';

  static Future<KoreanAddressResult?> showBottomSheet(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.82;

    return showModalBottomSheet<KoreanAddressResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(top: topInset + 8),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: sheetHeight,
            child: const KoreanAddressSearchScreen(inSheet: true),
          ),
        ),
      ),
    );
  }

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

  void _retry() {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    _controller.loadRequest(Uri.parse(KoreanAddressSearchScreen._searchUrl));
  }

  Widget _searchBody() {
    return Stack(
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
                    onPressed: _retry,
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sheetHeader() {
    return ColoredBox(
      color: AppTheme.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.paperDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    '주소 검색',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inSheet) {
      return ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            _sheetHeader(),
            Expanded(child: _searchBody()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('주소 검색'),
        backgroundColor: AppTheme.paper,
      ),
      body: _searchBody(),
    );
  }
}
