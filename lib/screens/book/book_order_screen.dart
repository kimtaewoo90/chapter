import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/korean_address_result.dart';

import '../../core/book_layout/book_layout_engine.dart';
import '../../core/book_layout/book_preview_entry_mapper.dart';
import '../../core/constants/book_cover_type.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/book_cover_date_range.dart';
import '../../core/utils/entry_photos.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../services/book_order_service.dart';
import '../../widgets/book_cover_artwork.dart';
import '../../widgets/book_pdf_preview.dart';
import '../../widgets/entry_photo.dart';
import '../../widgets/korean_address_input.dart';
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
  static const _stepLabels = ['표지', '미리보기', '주문정보', '주문'];

  final _bookOrderService = BookOrderService();
  final _nameController = TextEditingController();
  final _coverTitleController = TextEditingController();
  final _addressDetailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressDetailFocus = FocusNode();
  final _coverTitleFocus = FocusNode();

  String _addressBase = '';
  String _zoneCode = '';

  int _step = 0;
  String _cover = BookCoverType.chapterIcon;
  String? _coverPhotoUri;
  static const _style = 'classic';
  bool _hardcover = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _coverTitleController.dispose();
    _addressDetailController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressDetailFocus.dispose();
    _coverTitleFocus.dispose();
    super.dispose();
  }

  int get _amount => _hardcover ? BookOrderService.hardcoverPrice : BookOrderService.softcoverPrice;

  String? get _coverTitle {
    final t = _coverTitleController.text.trim();
    return t.isEmpty ? null : t;
  }

  String get _orderTitleLabel => _coverTitle ?? '';

  String get _fullShippingAddress {
    final detail = _addressDetailController.text.trim();
    if (detail.isEmpty) return _addressBase.trim();
    return '${_addressBase.trim()} $detail';
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onAddressSelected(KoreanAddressResult result) {
    setState(() {
      _zoneCode = result.postCode;
      _addressBase = result.userSelectedAddress;
    });
  }

  List<DailyEntry> _resolvedEntries(AppState state) {
    return widget.selectedEntries.map((selected) {
      for (final current in state.allEntries) {
        if (current.id == selected.id) return current;
      }
      return state.entryForDay(selected.date) ?? selected;
    }).toList();
  }

  Future<void> _submitOrder() async {
    final appState = context.read<AppState>();
    final authUid = appState.cloudAuthUid;
    if (authUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.lastCloudSyncError ??
                'Firebase 로그인 후 주문할 수 있어요. 설정에서 클라우드 연결을 확인해 주세요.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final order = await _bookOrderService.createOrder(
        userId: authUid,
        entries: _resolvedEntries(appState),
        bookTitle: _orderTitleLabel,
        recipientName: _nameController.text.trim(),
        shippingAddress: _fullShippingAddress,
        phoneNumber: _phoneController.text.trim(),
        hardcover: _hardcover,
        cover: _cover,
        coverPhotoUrl: _coverPhotoUri,
        coverTitle: _coverTitle,
        style: _style,
      );

      if (!mounted) return;
      context.read<AnalyticsService>().logBookOrderSubmit(
            pageCount: order.pageCount,
            hardcover: order.hardcover,
            amount: order.amount,
            cover: _cover,
            style: _style,
          );
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            order.bookTitle.isNotEmpty
                ? '「${order.bookTitle}」 주문이 접수됐어요. 내 책에서 진행 상황을 확인할 수 있어요.'
                : '주문이 접수됐어요. 내 책에서 진행 상황을 확인할 수 있어요.',
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

  bool _isOrderInfoValid() =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().length >= 10 &&
      _addressBase.trim().isNotEmpty;

  bool _canProceed() {
    if (_step == 0) {
      final sorted = List<DailyEntry>.from(_resolvedEntries(context.read<AppState>()))
        ..sort((a, b) => a.date.compareTo(b.date));
      return _canProceedCover(sorted);
    }
    if (_step == 2) return _isOrderInfoValid();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final sorted = List<DailyEntry>.from(_resolvedEntries(appState))
      ..sort((a, b) => a.date.compareTo(b.date));

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('실물 책 제작 (${sorted.length}일)'),
        ),
        body: Column(
          children: [
            _StepIndicator(current: _step, labels: _stepLabels),
            Expanded(child: _buildStep(sorted)),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  List<String> _photoUrisForCover(List<DailyEntry> sorted) {
    final uris = <String>[];
    final seen = <String>{};
    for (final entry in sorted) {
      for (final uri in EntryPhotos.displayUris(
        localPaths: entry.localPhotoPaths,
        remoteUrls: entry.remotePhotoUrls,
      )) {
        if (seen.add(uri)) uris.add(uri);
      }
    }
    return uris;
  }

  void _selectCoverType(String type, List<DailyEntry> sorted) {
    setState(() {
      _cover = type;
      if (type == BookCoverType.customPhoto) {
        final photos = _photoUrisForCover(sorted);
        if (photos.isEmpty) {
          _coverPhotoUri = null;
        } else if (_coverPhotoUri == null || !photos.contains(_coverPhotoUri)) {
          _coverPhotoUri = photos.first;
        }
      }
    });
  }

  bool _canProceedCover(List<DailyEntry> sorted) {
    if (_cover != BookCoverType.customPhoto) return true;
    return _coverPhotoUri != null;
  }

  Widget _buildStep(List<DailyEntry> sorted) {
    switch (_step) {
      case 0:
        return _coverStep(sorted);
      case 1:
        return _previewStep(sorted);
      case 2:
        return _orderInfoStep();
      default:
        return _confirmStep(sorted.length);
    }
  }

  Widget _coverStep(List<DailyEntry> sorted) {
    final textTheme = Theme.of(context).textTheme;
    final dateRange = bookCoverDateRangeLabel(sorted);
    final photoUris = _photoUrisForCover(sorted);
    final canPickPhoto = photoUris.isNotEmpty;

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('표지 선택', style: textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          '위에서 종류를 고르면 아래에 표지 미리보기가 나와요.',
          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted, height: 1.45),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _coverTypeChip(
                label: BookCoverType.label(BookCoverType.chapterIcon),
                icon: Icons.auto_stories_outlined,
                selected: _cover == BookCoverType.chapterIcon,
                onTap: () => _selectCoverType(BookCoverType.chapterIcon, sorted),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _coverTypeChip(
                label: BookCoverType.label(BookCoverType.customPhoto),
                icon: Icons.photo_outlined,
                selected: _cover == BookCoverType.customPhoto,
                enabled: canPickPhoto,
                onTap: canPickPhoto
                    ? () => _selectCoverType(BookCoverType.customPhoto, sorted)
                    : null,
              ),
            ),
          ],
        ),
        if (!canPickPhoto)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '사진이 있는 일기를 포함하면 사진 표지를 선택할 수 있어요.',
              style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
            ),
          ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: BookCoverArtwork(
              key: ValueKey('$_cover-${_coverPhotoUri ?? ''}-${_coverTitle ?? ''}'),
              coverType: _cover,
              dateRangeLabel: dateRange,
              photoUri: _coverPhotoUri,
              coverTitle: _coverTitle,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _coverTitleController,
          focusNode: _coverTitleFocus,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _dismissKeyboard(),
          decoration: InputDecoration(
            labelText: '표지 제목 (선택)',
            hintText: '비우면 제목 없이 인쇄돼요',
            counterText: '',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.paperDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.paperDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
            ),
          ),
          style: textTheme.bodyLarge,
        ),
        if (_cover == BookCoverType.customPhoto && canPickPhoto) ...[
          const SizedBox(height: 20),
          Text('표지 사진', style: textTheme.titleSmall),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUris.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final uri = photoUris[index];
                final selected = _coverPhotoUri == uri;
                return GestureDetector(
                  onTap: () => setState(() => _coverPhotoUri = uri),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppTheme.accent : AppTheme.paperDark,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: _coverPhotoThumb(uri),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
      ),
    );
  }

  Widget _coverTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    final active = enabled && onTap != null;
    return Material(
      color: selected
          ? AppTheme.accent.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.accent
                  : AppTheme.paperDark.withValues(alpha: active ? 1 : 0.6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active
                    ? AppTheme.accent
                    : AppTheme.inkMuted.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: active ? AppTheme.ink : AppTheme.inkMuted.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPhotoThumb(String uri) {
    if (uri.startsWith('http')) {
      return SizedBox(
        width: 72,
        height: 72,
        child: EntryPhoto(url: uri, height: 72, borderRadius: 0),
      );
    }
    return SizedBox(
      width: 72,
      height: 72,
      child: EntryPhoto(file: File(uri), height: 72, borderRadius: 0),
    );
  }

  Widget _orderInfoStep() {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('주문 정보', style: textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          '배송 정보를 입력해 주세요.',
          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted, height: 1.4),
        ),
        const SizedBox(height: 20),
        _OrderInfoCard(
          title: '받는 분',
          children: [
            _OrderInfoField(
              controller: _nameController,
              focusNode: _nameFocus,
              label: '이름',
              hint: '홍길동',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _phoneFocus.requestFocus(),
              onChanged: (_) => setState(() {}),
            ),
            const _OrderFieldDivider(),
            _OrderInfoField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              label: '전화번호',
              hint: '01012345678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                if (_addressBase.isNotEmpty) {
                  _addressDetailFocus.requestFocus();
                }
              },
              onChanged: (_) => setState(() {}),
            ),
            const _OrderFieldDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: KoreanAddressInput(
                baseAddress: _addressBase,
                zoneCode: _zoneCode,
                detailController: _addressDetailController,
                detailFocusNode: _addressDetailFocus,
                onAddressSelected: _onAddressSelected,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
        if (!_isOrderInfoValid()) ...[
          const SizedBox(height: 12),
          Text(
            '이름, 전화번호(10자리 이상), 주소 검색을 모두 입력해 주세요.',
            style: textTheme.labelSmall?.copyWith(color: AppTheme.inkMuted),
          ),
        ],
      ],
    );
  }

  Widget _previewStep(List<DailyEntry> sorted) {
    final pageCount = 1 +
        BookLayoutEngine.planBookPages(
          BookPreviewEntryMapper.fromDailyEntries(sorted),
        ).length;
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
          '$dateRange · $pageCount페이지 (표지 포함)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
        ),
        if (_coverTitle != null) ...[
          const SizedBox(height: 4),
          Text(
            '「$_coverTitle」 · ${BookCoverType.label(_cover)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            BookCoverType.label(_cover),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
          ),
        ],
        const SizedBox(height: 20),
        BookPdfPreview.fromDailyEntries(
          entries: sorted,
          bookTitle: _orderTitleLabel,
          coverType: _cover,
          coverDateRangeLabel: bookCoverDateRangeLabel(sorted),
          coverPhotoUri: _coverPhotoUri,
          coverTitle: _coverTitle,
        ),
      ],
    );
  }

  Widget _confirmStep(int dayCount) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('주문 확인', style: textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          '표지 종류와 최종 금액을 확인한 뒤 주문해 주세요.',
          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
        ),
        const SizedBox(height: 20),
        _OrderInfoCard(
          title: '주문 요약',
          children: [
            _SummaryRow(label: '받는 분', value: _nameController.text.trim()),
            const _OrderFieldDivider(),
            _SummaryRow(label: '연락처', value: _formatPhone(_phoneController.text.trim())),
            const _OrderFieldDivider(),
            _SummaryRow(label: '주소', value: _fullShippingAddress),
            const _OrderFieldDivider(),
            _SummaryRow(label: '포함 일기', value: '$dayCount일'),
            const _OrderFieldDivider(),
            _SummaryRow(
              label: '표지',
              value: BookCoverType.label(_cover),
            ),
            if (_coverTitle != null) ...[
              const _OrderFieldDivider(),
              _SummaryRow(label: '표지 제목', value: _coverTitle!),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Text('커버 종류', style: textTheme.titleSmall),
        const SizedBox(height: 10),
        _priceCard('하드커버', '${_amountFormat(BookOrderService.hardcoverPrice)}원', true),
        const SizedBox(height: 10),
        _priceCard('소프트커버', '${_amountFormat(BookOrderService.softcoverPrice)}원', false),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '주문 시 선택한 일기 스냅샷이 저장돼요.\n'
            '입금 대기 → 입금 확인 후 제작이 시작됩니다.',
            style: textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }

  String _formatPhone(String digits) {
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return digits;
  }

  Widget _priceCard(String title, String price, bool hard) {
    final sel = _hardcover == hard;
    return Material(
      color: sel ? AppTheme.accent.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _hardcover = hard),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppTheme.accent : AppTheme.paperDark, width: sel ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(price, style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                  ],
                ),
              ),
              if (sel) const Icon(Icons.check, color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final isLast = _step == _stepLabels.length - 1;

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
                      if (!isLast) {
                        setState(() => _step++);
                      } else {
                        _submitOrder();
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                minimumSize: Size(isLast ? 180 : 100, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isLast ? '주문하기 · ${_amountFormat(_amount)}원' : '다음'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.labels});

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i <= current;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.accent : AppTheme.paperDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: active ? AppTheme.accent : AppTheme.inkMuted,
                    fontWeight: i == current ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.paperDark.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.accent),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _OrderFieldDivider extends StatelessWidget {
  const _OrderFieldDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppTheme.paperDark.withValues(alpha: 0.7),
    );
  }
}

class _OrderInfoField extends StatelessWidget {
  const _OrderInfoField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: AppTheme.accent.withValues(alpha: 0.85)),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.inkMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
