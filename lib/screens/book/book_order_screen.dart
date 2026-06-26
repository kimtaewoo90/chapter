import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../services/book_order_service.dart';
import '../../widgets/paper_background.dart';

class BookOrderScreen extends StatefulWidget {
  const BookOrderScreen({
    super.key,
    required this.selectedEntries,
  });

  final List<DailyEntry> selectedEntries;

  @override
  State<BookOrderScreen> createState() => _BookOrderScreenState();
}

class _BookOrderScreenState extends State<BookOrderScreen> {
  final _bookOrderService = BookOrderService();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  int _step = 0;
  String _cover = 'linen';
  String _style = 'classic';
  bool _hardcover = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final year = DateTime.now().year;
    _titleController.text = '$year 나의 챕터';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get _amount => _hardcover ? BookOrderService.hardcoverPrice : BookOrderService.softcoverPrice;

  Future<void> _submitOrder() async {
    final appState = context.read<AppState>();
    final uid = appState.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 주문할 수 있어요.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final order = await _bookOrderService.createOrder(
        userId: uid,
        entries: widget.selectedEntries,
        bookTitle: _titleController.text,
        shippingAddress: _addressController.text,
        phoneNumber: _phoneController.text,
        hardcover: _hardcover,
        cover: _cover,
        style: _style,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '「${order.bookTitle}」 주문이 접수됐어요. 내 책에서 진행 상황을 확인할 수 있어요.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } on BookOrderException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주문 저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _amountFormat(int amount) => NumberFormat('#,###', 'ko_KR').format(amount);

  bool _canProceed() {
    if (_step == 3) {
      return _addressController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _titleController.text.trim().isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<DailyEntry>.from(widget.selectedEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('실물 책 제작 (${sorted.length}일)'),
        ),
        body: Column(
          children: [
            _StepIndicator(current: _step),
            Expanded(child: _buildStep(sorted)),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(List<DailyEntry> sorted) {
    switch (_step) {
      case 0:
        return _optionGrid('표지 선택', const [
          ('linen', '린넨', Icons.texture),
          ('matte', '매트', Icons.layers_outlined),
          ('leather', '레더', Icons.book),
        ], _cover, (v) => setState(() => _cover = v));
      case 1:
        return _optionGrid('스타일 선택', const [
          ('classic', '클래식', Icons.article_outlined),
          ('cinematic', '시네마틱', Icons.movie_creation_outlined),
          ('warm', '웜', Icons.wb_sunny_outlined),
        ], _style, (v) => setState(() => _style = v));
      case 2:
        return _previewStep(sorted);
      default:
        return _shippingStep();
    }
  }

  Widget _previewStep(List<DailyEntry> sorted) {
    final snapshots = _bookOrderService.buildSnapshots(sorted);
    final dateRange = sorted.length == 1
        ? DateFormat('M월 d일', 'ko_KR').format(sorted.first.date)
        : '${DateFormat('M월 d일', 'ko_KR').format(sorted.first.date)} – '
            '${DateFormat('M월 d일', 'ko_KR').format(sorted.last.date)}';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('미리보기', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '$dateRange · ${sorted.length}페이지',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            height: 160,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: AppTheme.warmShadow, blurRadius: 16)],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _titleController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$_cover · $_style',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Text('포함된 일기', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...snapshots.take(8).map(
              (s) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bookmark_outline, size: 18, color: AppTheme.accent),
                title: Text(s.title, style: const TextStyle(fontSize: 14)),
                subtitle: s.body.isNotEmpty
                    ? Text(s.body, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : (s.photoUrls.isNotEmpty ? const Text('사진') : null),
              ),
            ),
        if (snapshots.length > 8)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '외 ${snapshots.length - 8}일…',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
            ),
          ),
      ],
    );
  }

  Widget _shippingStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('배송 · 주문', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '책 제목',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: '배송 주소',
            hintText: '서울시 강남구 테헤란로 123',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: '연락처',
            hintText: '01012345678',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        _priceCard('하드커버', '${_amountFormat(BookOrderService.hardcoverPrice)}원', true),
        const SizedBox(height: 12),
        _priceCard('소프트커버', '${_amountFormat(BookOrderService.softcoverPrice)}원', false),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '주문 시 선택한 일기의 스냅샷이 Firestore에 저장돼요.\n'
            '상태: 입금 대기 → 관리자 입금 확인 후 제작',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }

  Widget _optionGrid(
    String title,
    List<(String, String, IconData)> options,
    String selected,
    ValueChanged<String> onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          ...options.map((o) {
            final isSel = selected == o.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSel ? AppTheme.accent : AppTheme.paperDark),
                ),
                tileColor: isSel ? AppTheme.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6),
                leading: Icon(o.$3, color: AppTheme.accent),
                title: Text(o.$2),
                trailing: isSel ? const Icon(Icons.check_circle, color: AppTheme.accent) : null,
                onTap: () => onSelect(o.$1),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _priceCard(String title, String price, bool hard) {
    final sel = _hardcover == hard;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: sel ? AppTheme.accent : AppTheme.paperDark, width: sel ? 2 : 1),
      ),
      tileColor: sel ? AppTheme.accent.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6),
      title: Text(title),
      subtitle: Text(price),
      trailing: sel ? const Icon(Icons.check, color: AppTheme.accent) : null,
      onTap: () => setState(() => _hardcover = hard),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            if (_step > 0)
              TextButton(
                onPressed: _submitting ? null : () => setState(() => _step--),
                child: const Text('이전'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _submitting || !_canProceed()
                  ? null
                  : () {
                      if (_step < 3) {
                        setState(() => _step++);
                      } else {
                        _submitOrder();
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_step < 3 ? '다음' : '주문하기 · ${_amountFormat(_amount)}원'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['표지', '스타일', '미리보기', '주문'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (i) {
          final active = i <= current;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.accent : AppTheme.paperDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: TextStyle(fontSize: 10, color: active ? AppTheme.accent : AppTheme.inkMuted),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
