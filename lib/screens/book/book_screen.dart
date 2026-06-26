import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_diary_ai.dart';
import '../../core/utils/entry_photos.dart';
import '../../models/book_order.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../services/book_order_service.dart';
import '../../widgets/book_order_progress.dart';
import '../../widgets/chapter_bottom_bar.dart';
import '../../widgets/entry_photo_grid.dart';
import '../../widgets/paper_background.dart';
import 'book_entry_select_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _pageController = PageController();
  final _orderService = BookOrderService();
  int _currentPage = 0;
  bool _showPreview = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startNewBook() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookEntrySelectScreen()),
    );
  }

  Future<void> _exportPdf(BuildContext context, List<DailyEntry> entries) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('CHAPTER', style: pw.TextStyle(fontSize: 24))),
          pw.SizedBox(height: 12),
          ...entries.take(50).map((e) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(DateFormat('yyyy.MM.dd').format(e.date), style: const pw.TextStyle(fontSize: 10)),
                if (EntryDiaryAi.primaryDiaryText(e) != null)
                  pw.Text(
                    EntryDiaryAi.primaryDiaryText(e)!,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: EntryDiaryAi.shouldShowAiLine(e)
                          ? pw.FontStyle.italic
                          : pw.FontStyle.normal,
                    ),
                  ),
                pw.SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final uid = state.uid;
    final entries = state.allEntries;
    final progress = state.bookProgress;
    final bottomPad = widget.embedInShell ? ChapterBottomBar.listBottomPadding(context) : 0.0;
    final textTheme = Theme.of(context).textTheme;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('내 책')),
        body: uid == null
            ? Center(
                child: Text(
                  '앱을 시작한 뒤\n책 주문 내역을 볼 수 있어요.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted, height: 1.5),
                ),
              )
            : StreamBuilder<List<BookOrder>>(
                stream: _orderService.watchOrdersForUser(uid),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? const [];
                  final activeOrders = orders
                      .where((o) => BookOrderPipeline.isInProgress(o.status))
                      .toList();
                  final pastOrders = orders
                      .where((o) => !BookOrderPipeline.isInProgress(o.status))
                      .toList();
                  final hasOrders = orders.isNotEmpty;

                  if (snapshot.hasError) {
                    return _OrdersErrorBody(
                      message: '주문 내역을 불러오지 못했어요.\n네트워크·Firestore 규칙을 확인해 주세요.',
                      onRetry: () => setState(() {}),
                      onNewBook: _startNewBook,
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomPad),
                    children: [
                      if (hasOrders) ...[
                        Text('책 제작 현황', style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '주문한 책의 진행 단계를 확인할 수 있어요.',
                          style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                        ),
                        const SizedBox(height: 16),
                        if (activeOrders.isEmpty && pastOrders.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '지금 제작 중인 책은 없어요.',
                              style: textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                            ),
                          ),
                        for (final order in activeOrders)
                          BookOrderProgressCard(order: order),
                        if (pastOrders.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('지난 주문', style: textTheme.labelLarge?.copyWith(color: AppTheme.inkMuted)),
                          const SizedBox(height: 8),
                          for (final order in pastOrders)
                            BookOrderProgressCard(order: order, compact: true),
                        ],
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _startNewBook,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('다른 책 만들기'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _PreviewToggle(
                          expanded: _showPreview,
                          onTap: () => setState(() => _showPreview = !_showPreview),
                        ),
                        if (_showPreview) ...[
                          const SizedBox(height: 12),
                          _DigitalPreviewSection(
                            entries: entries,
                            progress: progress,
                            estimatedPages: state.estimatedPages,
                            currentPage: _currentPage,
                            pageController: _pageController,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            onExportPdf: entries.isEmpty ? null : () => _exportPdf(context, entries),
                          ),
                        ],
                      ] else
                        _EmptyOrdersBody(
                          entries: entries,
                          progress: progress,
                          estimatedPages: state.estimatedPages,
                          currentPage: _currentPage,
                          pageController: _pageController,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          onExportPdf: entries.isEmpty ? null : () => _exportPdf(context, entries),
                          onStartBook: _startNewBook,
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _OrdersErrorBody extends StatelessWidget {
  const _OrdersErrorBody({
    required this.message,
    required this.onRetry,
    required this.onNewBook,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onNewBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onNewBook,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('책 만들기'),
          ),
        ],
      ),
    );
  }
}

class _PreviewToggle extends StatelessWidget {
  const _PreviewToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_stories_outlined, size: 20, color: AppTheme.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '디지털 미리보기',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrdersBody extends StatelessWidget {
  const _EmptyOrdersBody({
    required this.entries,
    required this.progress,
    required this.estimatedPages,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
    required this.onExportPdf,
    required this.onStartBook,
  });

  final List<DailyEntry> entries;
  final double progress;
  final int estimatedPages;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onExportPdf;
  final VoidCallback onStartBook;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookCover(progress: progress, pages: estimatedPages),
        const SizedBox(height: 8),
        Text(
          '올해의 이야기 ${(progress * 100).round()}% 완성',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    '기록이 쌓이면\n여기서 책을 펼칠 수 있어요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: pageController,
                        onPageChanged: onPageChanged,
                        itemCount: entries.length,
                        itemBuilder: (context, i) => _BookPage(entry: entries[i]),
                      ),
                    ),
                    Text(
                      '${currentPage + 1} / ${entries.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onExportPdf,
                child: const Text('PDF 저장'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onStartBook,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.accent),
                child: const Text('실물 책 만들기'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DigitalPreviewSection extends StatelessWidget {
  const _DigitalPreviewSection({
    required this.entries,
    required this.progress,
    required this.estimatedPages,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
    required this.onExportPdf,
  });

  final List<DailyEntry> entries;
  final double progress;
  final int estimatedPages;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BookCover(progress: progress, pages: estimatedPages, compact: true),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    '기록이 없어요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.inkMuted),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: pageController,
                        onPageChanged: onPageChanged,
                        itemCount: entries.length,
                        itemBuilder: (context, i) => _BookPage(entry: entries[i]),
                      ),
                    ),
                    Text(
                      '${currentPage + 1} / ${entries.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onExportPdf,
          child: const Text('PDF 저장'),
        ),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.progress,
    required this.pages,
    this.compact = false,
  });

  final double progress;
  final int pages;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 56 : 48),
      height: compact ? 100 : 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C5048), Color(0xFF8B7355), Color(0xFF5C5048)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmShadow,
            blurRadius: compact ? 12 : 20,
            offset: Offset(compact ? 3 : 6, compact ? 5 : 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateTime.now().year.toString(),
                  style: TextStyle(
                    color: Colors.white54,
                    letterSpacing: 4,
                    fontSize: compact ? 10 : 12,
                  ),
                ),
                Text(
                  'MY CHAPTER',
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: compact ? 4 : 6,
                    fontSize: compact ? 14 : 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: compact ? 4 : 8),
                Text(
                  '$pages pages',
                  style: TextStyle(color: Colors.white54, fontSize: compact ? 10 : 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookPage extends StatelessWidget {
  const _BookPage({required this.entry});

  final DailyEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('M월 d일', 'ko_KR');
    final diaryFontId = context.watch<AppState>().diaryFontId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: AppTheme.warmShadow, blurRadius: 16, offset: const Offset(2, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(dateFmt.format(entry.date), style: Theme.of(context).textTheme.titleMedium),
              if (entry.moodEmoji != null) ...[
                const SizedBox(height: 8),
                Text(entry.moodEmoji!, style: const TextStyle(fontSize: 28)),
              ],
              if (entry.hasPhotos) ...[
                const SizedBox(height: 16),
                EntryPhotoGrid(
                  localPaths: EntryPhotos.displayUris(
                    localPaths: entry.localPhotoPaths,
                    remoteUrls: entry.remotePhotoUrls,
                  ),
                  height: 160,
                ),
              ],
              if (EntryDiaryAi.primaryDiaryText(entry) != null) ...[
                const SizedBox(height: 16),
                Text(
                  EntryDiaryAi.primaryDiaryText(entry)!,
                  style: diaryFontStyle(
                    diaryFontId,
                    fontSize: 15,
                    height: 1.6,
                    fontStyle: EntryDiaryAi.shouldShowAiLine(entry)
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: EntryDiaryAi.shouldShowAiLine(entry) ? AppTheme.accent : null,
                  ),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
