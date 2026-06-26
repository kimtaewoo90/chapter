import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../widgets/font_settings_section.dart';
import '../../widgets/paper_background.dart';

class FontSettingsScreen extends StatelessWidget {
  const FontSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return PaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('글꼴')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FontPickerSection(
              title: '앱 글꼴',
              subtitle: '메뉴·버튼·제목 등 전체 UI',
              selected: state.fontId,
              onSelect: (id) async {
                await context.read<AppState>().setFontId(id);
                if (!context.mounted) return;
                final state = context.read<AppState>();
                context.read<AnalyticsService>().logFontChange(
                      appFont: state.fontId.name,
                      diaryFont: state.diaryFontId.name,
                    );
              },
            ),
            const SizedBox(height: 32),
            FontPickerSection(
              title: '일기 글꼴',
              subtitle: '기록 입력·피드·책 본문',
              selected: state.diaryFontId,
              onSelect: (id) async {
                await context.read<AppState>().setDiaryFontId(id);
                if (!context.mounted) return;
                final state = context.read<AppState>();
                context.read<AnalyticsService>().logFontChange(
                      appFont: state.fontId.name,
                      diaryFont: state.diaryFontId.name,
                    );
              },
              previewText: '오늘 마음에 남는 것을 적어 보세요…',
              previewUsesDiaryStyle: true,
            ),
          ],
        ),
      ),
    );
  }
}
