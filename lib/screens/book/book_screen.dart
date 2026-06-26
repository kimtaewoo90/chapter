import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_route.dart';
import '../../core/book_layout/book_layout_engine.dart';
import '../../core/book_layout/book_preview_entry_mapper.dart';
import '../../core/theme/app_theme.dart';
import '../../models/book_order.dart';
import '../../models/daily_entry.dart';
import '../../providers/app_state.dart';
import '../../services/book_order_service.dart';
import '../../widgets/book_order_progress.dart';
import '../../widgets/book_pdf_preview.dart';
import '../../widgets/chapter_bottom_bar.dart';
import '../../widgets/paper_background.dart';
import 'book_entry_select_screen.dart';
import 'book_order_preview_screen.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _orderService = BookOrderService();

  void _startNewBook() {
    Navigator.push(
      context,
      analyticsPageRoute(
        name: 'book_entry_select',
        builder: (_) => const BookEntrySelectScreen(),
      ),
    );
  }

  void _openOrderPreview(BookOrder order) {
    Navigator.push(
      context,
      analyticsPageRoute(
        name: 'book_order_preview',
        builder: (_) => BookOrderPreviewScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final authUid = state.cloudAuthUid;
    final entries = state.allEntries;
    final progress = state.bookProgress;
    final bottomPad = widget.embedInShell ? ChapterBottomBar.listBottomPadding(context) : 0.0;
    final textTheme = Theme.of(context).textTheme;

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('내 책')),
        body: authUid == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.lastCloudSyncError ??
                            'Firebase 로그인이 필요해요.\n주문 내역은 클라우드 계정과 연결된 뒤 볼 수 있어요.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () async {
                          await context.read<AppState>().retryCloudAuth();
                        },
                        child: const Text('클라우드 연결 다시 시도'),
                      ),
                    ],
                  ),
                ),
              )
            : StreamBuilder<List<BookOrder>>(
                stream: _orderService.watchOrdersForUser(authUid),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? const [];
                  final visibleOrders =
                      orders.where((o) => o.status.showInBookList).toList();
                  final hasVisibleOrders = visibleOrders.isNotEmpty;

                  if (snapshot.hasError) {
                    final err = snapshot.error.toString();
                    final hint = err.contains('failed-precondition')
                        ? 'Firestore 색인이 필요해요. Firebase Console에서 orders(userId, createdAt) 색인을 배포해 주세요.'
                        : err.contains('permission-denied')
                            ? 'Firestore 권한 거부 — Firebase 익명 로그인과 rules 배포를 확인해 주세요.'
                            : '주문 내역을 불러오지 못했어요.\n네트워크를 확인해 주세요.';
                    return _OrdersErrorBody(
                      message: hint,
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
                      if (hasVisibleOrders) ...[
                        Text('책 제작 현황', style: textTheme.titleMedium),
                        const SizedBox(height: 16),
                        for (final order in visibleOrders)
                          BookOrderProgressCard(
                            order: order,
                            onTap: () => _openOrderPreview(order),
                          ),
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
                      ] else if (orders.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '진행 중인 주문이 없어요.\n배송이 완료된 책은 목록에서 숨겨져요.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.inkMuted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20),
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
                          ],
                        )
                      else
                        _EmptyOrdersBody(
                          entries: entries,
                          progress: progress,
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

class _EmptyOrdersBody extends StatelessWidget {
  const _EmptyOrdersBody({
    required this.entries,
    required this.progress,
    required this.onStartBook,
  });

  final List<DailyEntry> entries;
  final double progress;
  final VoidCallback onStartBook;

  @override
  Widget build(BuildContext context) {
    final sorted = List<DailyEntry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));
    final bookTitle = '${DateTime.now().year} 나의 챕터';
    final pageCount = sorted.isEmpty
        ? 0
        : 1 +
            BookLayoutEngine.planBookPages(
              BookPreviewEntryMapper.fromDailyEntries(sorted),
            ).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookCover(progress: progress, pages: pageCount > 0 ? pageCount : context.read<AppState>().estimatedPages),
        const SizedBox(height: 8),
        Text(
          '올해의 이야기 ${(progress * 100).round()}% 완성',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
        ),
        const SizedBox(height: 20),
        Text('디지털 미리보기', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          sorted.isEmpty
              ? '기록이 쌓이면 인쇄 PDF와 같은 형태로 미리볼 수 있어요.'
              : '지금까지의 기록을 실물 책 PDF와 같은 배치로 볼 수 있어요.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
        ),
        const SizedBox(height: 16),
        if (sorted.isEmpty)
          Container(
            height: 200,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.paperDark),
            ),
            child: Text(
              '기록이 쌓이면\n여기서 책을 펼칠 수 있어요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkMuted, height: 1.5),
            ),
          )
        else
          BookPdfPreview.fromDailyEntries(
            entries: sorted,
            bookTitle: bookTitle,
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onStartBook,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accent,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('실물 책 만들기'),
        ),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.progress,
    required this.pages,
  });

  final double progress;
  final int pages;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C5048), Color(0xFF8B7355), Color(0xFF5C5048)],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.warmShadow,
            blurRadius: 20,
            offset: Offset(6, 10),
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
                  style: const TextStyle(
                    color: Colors.white54,
                    letterSpacing: 4,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'MY CHAPTER',
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 6,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pages pages',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
