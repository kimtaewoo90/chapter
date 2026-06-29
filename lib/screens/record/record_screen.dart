import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/diary_limits.dart';
import '../../core/constants/moods.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/entry_diary_ai.dart';
import '../../core/utils/entry_photos.dart';
import '../../core/utils/picked_photo_processor.dart';
import '../../models/daily_entry.dart';
import '../../models/record_save_step.dart';
import '../../providers/app_state.dart';
import '../../services/analytics_service.dart';
import '../../widgets/record_save_overlay.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/paper_background.dart';
import '../../widgets/paper_journal_field.dart';
import '../../widgets/today_photo_section.dart';
import '../../widgets/today_weather_line.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    this.targetDate,
    this.isActive = false,
    this.onSavedSuccessfully,
  });

  /// 기록 대상 날짜 (null이면 오늘)
  final DateTime? targetDate;

  /// IndexedStack에서 기록 탭이 보일 때 true
  final bool isActive;

  /// 저장 완료 후 상위(MainShell)에서 오늘 탭 등으로 전환
  final VoidCallback? onSavedSuccessfully;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _noteController = TextEditingController();
  final _noteFocusNode = FocusNode();
  final _picker = ImagePicker();

  DateTime _day(AppState appState) =>
      widget.targetDate ?? appState.todayDate;

  DailyEntry? _entryForDay(AppState appState) => appState.entryForDay(_day(appState));

  List<String> _keptLocalPaths = [];
  List<String> _keptRemoteUrls = [];
  final List<File> _newPhotoFiles = [];
  String? _moodEmoji;
  String? _moodLabel;
  bool _saving = false;
  RecordSaveStep _saveStep = RecordSaveStep.preparingPhotos;
  bool _saveOverlayComplete = false;
  bool _savedAnim = false;
  bool _photosEdited = false;
  bool _pickingPhotos = false;
  String? _syncedEntryId;
  List<MoodOption> _aiSuggestedMoods = [];
  bool _loadingAiMoodSuggestions = false;
  String? _lastMoodSuggestFingerprint;
  int _moodSuggestRequestId = 0;
  Timer? _moodSuggestDebounce;

  void _syncFromEntry(DailyEntry? entry) {
    if (entry == null) return;
    final slots = EntryPhotos.editSlots(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );
    setState(() {
      _syncedEntryId = entry.id;
      _moodEmoji = entry.moodEmoji;
      _moodLabel = entry.moodLabel;
      _noteController.text = entry.note ?? '';
      _keptLocalPaths = slots.localPaths;
      _keptRemoteUrls = slots.remoteUrls;
      _photosEdited = false;
      _newPhotoFiles.clear();
    });
    _scheduleAiMoodSuggestions();
  }

  List<File> _photoFilesForAi() {
    final files = <File>[];
    for (final f in _newPhotoFiles) {
      if (f.existsSync()) files.add(f);
    }
    for (final path in _keptLocalPaths) {
      if (path.isEmpty || path.startsWith('http')) continue;
      final f = File(path);
      if (f.existsSync() && !files.any((x) => x.path == f.path)) {
        files.add(f);
      }
    }
    return files.take(DiaryLimits.maxPhotosPerEntry).toList();
  }

  String _photoFingerprint() {
    final parts = [
      ..._keptLocalPaths,
      ..._newPhotoFiles.map((f) => f.path),
    ]..sort();
    return parts.join('|');
  }

  void _scheduleAiMoodSuggestions() {
    _moodSuggestDebounce?.cancel();
    _moodSuggestDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _fetchAiMoodSuggestions();
    });
  }

  int _photoCount(DailyEntry? entry) => _displayPhotoUris(entry).length;

  int _remainingPhotoSlots(DailyEntry? entry) =>
      DiaryLimits.maxPhotosPerEntry - _photoCount(entry);

  Future<void> _addStagedPhotos(List<File> staged, DailyEntry? entry) async {
    if (staged.isEmpty) return;
    final remaining = _remainingPhotoSlots(entry);
    if (remaining <= 0) {
      _showPickError('사진은 하루 최대 ${DiaryLimits.maxPhotosPerEntry}장까지예요.');
      return;
    }
    final toAdd = staged.take(remaining).toList();
    if (toAdd.length < staged.length) {
      _showPickError(
        '사진은 하루 최대 ${DiaryLimits.maxPhotosPerEntry}장까지예요. ${toAdd.length}장만 추가했어요.',
      );
    }
    setState(() {
      _ensurePhotoEditState(entry);
      _photosEdited = true;
      _keptLocalPaths.addAll(toAdd.map((f) => f.path));
      while (_keptRemoteUrls.length < _keptLocalPaths.length) {
        _keptRemoteUrls.add('');
      }
    });
    _scheduleAiMoodSuggestions();
  }

  void _showPickError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _fetchAiMoodSuggestions() async {
    final files = _photoFilesForAi();
    if (files.isEmpty) {
      if (!mounted) return;
      setState(() {
        _aiSuggestedMoods = [];
        _loadingAiMoodSuggestions = false;
        _lastMoodSuggestFingerprint = null;
      });
      return;
    }

    final fingerprint = _photoFingerprint();
    if (fingerprint == _lastMoodSuggestFingerprint && !_loadingAiMoodSuggestions) {
      return;
    }

    final requestId = ++_moodSuggestRequestId;
    setState(() => _loadingAiMoodSuggestions = true);

    final suggestions = await context.read<AppState>().suggestMoodsFromPhotos(
          photoFiles: files,
          note: _noteController.text.trim(),
        );

    if (!mounted || requestId != _moodSuggestRequestId) return;

    setState(() {
      _loadingAiMoodSuggestions = false;
      _lastMoodSuggestFingerprint = fingerprint;
      _aiSuggestedMoods = suggestions;
    });
  }

  void _ensurePhotoEditState(DailyEntry? entry) {
    if (entry == null || _photosEdited) return;
    final slots = EntryPhotos.editSlots(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );
    _keptLocalPaths = slots.localPaths;
    _keptRemoteUrls = slots.remoteUrls;
  }

  List<String> _displayPhotoUris(DailyEntry? entry) {
    if (_photosEdited || _newPhotoFiles.isNotEmpty) {
      return EntryPhotos.displayUris(
        localPaths: _keptLocalPaths,
        remoteUrls: _keptRemoteUrls,
        verifyLocalFiles: false,
      );
    }
    if (entry == null) return [];
    return EntryPhotos.displayUris(
      localPaths: entry.localPhotoPaths,
      remoteUrls: entry.remotePhotoUrls,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppState>();
      final day = widget.targetDate ?? appState.todayDate;
      final entry = appState.entryForDay(day);
      if (entry != null && !_photosEdited) {
        _syncFromEntry(entry);
      }
      if (appState.isToday(day)) {
        appState.refreshTodayWeatherIfNeeded();
      }
    });
  }

  @override
  void didUpdateWidget(RecordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // 빌드 중 setState / Provider notify 금지 → 다음 프레임에 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final appState = context.read<AppState>();
        final entry = _entryForDay(appState);
        if (entry != null && !_photosEdited) {
          _syncFromEntry(entry);
        }
        if (appState.isToday(_day(appState))) {
          appState.refreshTodayWeatherIfNeeded();
        }
      });
    }
  }

  @override
  void dispose() {
    _moodSuggestDebounce?.cancel();
    _noteFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<List<XFile>> _pickGalleryImages(int remaining) async {
    final options = (
      maxWidth: PickedPhotoProcessor.maxWidth,
      maxHeight: PickedPhotoProcessor.maxHeight,
      imageQuality: PickedPhotoProcessor.imageQuality,
    );

    // image_picker: pickMultiImage limit는 2 이상만 허용
    if (remaining <= 1) {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
        maxWidth: options.maxWidth,
        maxHeight: options.maxHeight,
        imageQuality: options.imageQuality,
      );
      return image == null ? const [] : [image];
    }

    return _picker.pickMultiImage(
      requestFullMetadata: false,
      maxWidth: options.maxWidth,
      maxHeight: options.maxHeight,
      imageQuality: options.imageQuality,
      limit: remaining,
    );
  }

  Future<void> _pickMultiple() async {
    final entry = _entryForDay(context.read<AppState>());
    final remaining = _remainingPhotoSlots(entry);
    if (remaining <= 0) {
      _showPickError('사진은 하루 최대 ${DiaryLimits.maxPhotosPerEntry}장까지예요.');
      return;
    }
    try {
      final images = await _pickGalleryImages(remaining);
      if (!mounted || images.isEmpty) return;

      setState(() => _pickingPhotos = true);
      final staged = <File>[];
      for (final x in images) {
        final file = await PickedPhotoProcessor.stage(x);
        if (file != null) staged.add(file);
      }
      if (!mounted) return;
      if (staged.isEmpty) {
        _showPickError('사진을 불러오지 못했어요. 다시 시도해 주세요.');
        return;
      }
      await _addStagedPhotos(staged, entry);
    } catch (e) {
      if (mounted) _showPickError('갤러리를 열지 못했어요. 권한을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  Future<void> _pickCamera() async {
    final entry = _entryForDay(context.read<AppState>());
    if (_remainingPhotoSlots(entry) <= 0) {
      _showPickError('사진은 하루 최대 ${DiaryLimits.maxPhotosPerEntry}장까지예요.');
      return;
    }
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
        maxWidth: PickedPhotoProcessor.maxWidth,
        maxHeight: PickedPhotoProcessor.maxHeight,
        imageQuality: PickedPhotoProcessor.imageQuality,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted || x == null) return;

      setState(() => _pickingPhotos = true);
      final staged = await PickedPhotoProcessor.stage(x);
      if (!mounted) return;
      if (staged == null) {
        _showPickError('사진을 저장하지 못했어요. 다시 찍어 주세요.');
        return;
      }
      await _addStagedPhotos([staged], entry);
    } catch (e) {
      if (mounted) {
        _showPickError('카메라를 열지 못했어요. 설정에서 카메라 권한을 허용해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  void _removeDisplayUri(String uri, DailyEntry? entry) {
    setState(() {
      _ensurePhotoEditState(entry);
      _photosEdited = true;

      var removed = false;
      for (var i = 0; i < _keptLocalPaths.length; i++) {
        final local = _keptLocalPaths[i];
        String? candidate;
        if (local.isNotEmpty && File(local).existsSync()) {
          candidate = local;
        } else if (i < _keptRemoteUrls.length && _keptRemoteUrls[i].isNotEmpty) {
          candidate = _keptRemoteUrls[i];
        } else if (local.startsWith('http')) {
          candidate = local;
        }
        if (candidate == uri) {
          _keptLocalPaths.removeAt(i);
          if (i < _keptRemoteUrls.length) {
            _keptRemoteUrls.removeAt(i);
          }
          removed = true;
          break;
        }
      }

      if (!removed) {
        final i = _keptRemoteUrls.indexOf(uri);
        if (i >= 0) {
          _keptRemoteUrls.removeAt(i);
          if (i < _keptLocalPaths.length) {
            _keptLocalPaths.removeAt(i);
          }
        }
      }
    });
    _scheduleAiMoodSuggestions();
  }

  void _reorderCombinedPhotos({
    required List<String> reorderedDisplayUris,
    required List<File> reorderedNewFiles,
    required DailyEntry? entry,
  }) {
    setState(() {
      _ensurePhotoEditState(entry);
      _photosEdited = true;

      // displayUris 순서를 keptLocal/keptRemote 순서로 재정렬
      final pairs = <({int index, String uri})>[];
      for (var i = 0; i < _keptLocalPaths.length; i++) {
        final local = _keptLocalPaths[i];
        String? uri;
        if (local.isNotEmpty && File(local).existsSync()) {
          uri = local;
        } else if (i < _keptRemoteUrls.length && _keptRemoteUrls[i].isNotEmpty) {
          uri = _keptRemoteUrls[i];
        } else if (local.startsWith('http')) {
          uri = local;
        }
        if (uri != null) {
          pairs.add((index: i, uri: uri));
        }
      }

      final used = <int>{};
      final orderedIndices = <int>[];
      for (final uri in reorderedDisplayUris) {
        for (final pair in pairs) {
          if (!used.contains(pair.index) && pair.uri == uri) {
            used.add(pair.index);
            orderedIndices.add(pair.index);
            break;
          }
        }
      }
      for (var i = 0; i < _keptLocalPaths.length; i++) {
        if (!orderedIndices.contains(i)) {
          orderedIndices.add(i);
        }
      }

      _keptLocalPaths = [for (final i in orderedIndices) _keptLocalPaths[i]];
      _keptRemoteUrls = [for (final i in orderedIndices.where((i) => i < _keptRemoteUrls.length)) _keptRemoteUrls[i]];

      _newPhotoFiles
        ..clear()
        ..addAll(reorderedNewFiles);
    });
  }

  Future<void> _save() async {
    _noteFocusNode.unfocus();
    DismissKeyboard.unfocus(context);

    setState(() {
      _saving = true;
      _saveOverlayComplete = false;
      _saveStep = RecordSaveStep.preparingPhotos;
    });
    try {
      final appState = context.read<AppState>();
      final day = _day(appState);
      final saved = await appState.saveEntry(
            date: day,
            newPhotoFiles: List.from(_newPhotoFiles),
            keepLocalPaths: _photosEdited ? _keptLocalPaths : null,
            keepRemoteUrls: _photosEdited ? _keptRemoteUrls : null,
            moodEmoji: _moodEmoji,
            moodLabel: _moodLabel,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            onStep: (step) {
              if (mounted) setState(() => _saveStep = step);
            },
          );
      if (mounted) {
        setState(() => _saveOverlayComplete = true);
        await Future.delayed(const Duration(milliseconds: 650));
      }
      if (!mounted) return;
      context.read<AnalyticsService>().logDiarySave(
            isToday: appState.isToday(day),
            hasPhotos: saved.hasPhotos,
            hasMood: saved.moodEmoji != null,
            hasNote: saved.note != null && saved.note!.trim().isNotEmpty,
            hasAiLine: EntryDiaryAi.primaryDiaryText(saved) != null,
          );
      setState(() {
        _saving = false;
        _saveOverlayComplete = false;
        _savedAnim = true;
        _syncFromEntry(saved);
      });
      widget.onSavedSuccessfully?.call();
      if (mounted) {
        final cloudMsg = appState.lastCloudSyncError;
        final savedLabel = appState.isToday(day)
            ? '오늘이 책에 남았습니다.'
            : '${DateFormat('M월 d일', 'ko_KR').format(day)} 기록을 저장했어요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cloudMsg != null
                  ? '이 기기에 저장됐어요. $cloudMsg'
                  : savedLabel,
            ),
            duration: Duration(seconds: cloudMsg != null ? 5 : 3),
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _savedAnim = false);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        _noteFocusNode.unfocus();
        DismissKeyboard.unfocus(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final day = _day(appState);
    final entry = _entryForDay(appState);
    final isToday = appState.isToday(day);

    if (entry != null && entry.id != _syncedEntryId && !_photosEdited && _newPhotoFiles.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && entry.id != _syncedEntryId) {
          _syncFromEntry(entry);
        }
      });
    } else if (entry == null && _syncedEntryId != null && !_photosEdited) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _syncedEntryId = null;
          _moodEmoji = null;
          _moodLabel = null;
          _noteController.clear();
          _keptLocalPaths = [];
          _keptRemoteUrls = [];
          _newPhotoFiles.clear();
        });
      });
    }

    final displayUris = _displayPhotoUris(entry);
    final title = isToday
        ? '오늘의 한 페이지'
        : DateFormat('M월 d일 기록', 'ko_KR').format(day);

    return PaperBackground(
      child: Stack(
        children: [
          Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: DismissKeyboard(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '연필로 적듯, 편하게 남겨 보세요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.inkMuted,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              MoodSelector(
                moods: context.watch<AppState>().personalizedMoods,
                recentMoods: context.watch<AppState>().recentMoods,
                aiSuggestedMoods: _aiSuggestedMoods,
                loadingAiSuggestions: _loadingAiMoodSuggestions,
                selectedEmoji: _moodEmoji,
                selectedLabel: _moodLabel,
                onSelected: (m) => setState(() {
                  _moodEmoji = m.emoji;
                  _moodLabel = m.label;
                }),
                onAddCustom: (m) => context.read<AppState>().addCustomMood(m),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 장면',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '최대 ${DiaryLimits.maxPhotosPerEntry}장',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.inkMuted,
                          ),
                    ),
                    const SizedBox(height: 10),
                    TodayPhotoSection(
                      displayUris: displayUris,
                      newPhotoFiles: _newPhotoFiles,
                      maxPhotos: DiaryLimits.maxPhotosPerEntry,
                      isPickingPhotos: _pickingPhotos,
                      onPickMultiple: _pickMultiple,
                      onPickCamera: _pickCamera,
                      onRemoveDisplay: (uri) => _removeDisplayUri(uri, entry),
                      onRemoveNew: (i) => setState(() {
                        _photosEdited = true;
                        _newPhotoFiles.removeAt(i);
                        _scheduleAiMoodSuggestions();
                      }),
                      onReorderCombined: (reorderedDisplay, reorderedNew) => _reorderCombinedPhotos(
                        reorderedDisplayUris: reorderedDisplay,
                        reorderedNewFiles: reorderedNew,
                        entry: entry,
                      ),
                    ).animate(target: _savedAnim ? 1 : 0).shimmer(duration: 600.ms),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PaperJournalField(
                controller: _noteController,
                focusNode: _noteFocusNode,
                minLines: 12,
                maxLength: 500,
              ),
              const SizedBox(height: 12),
              if (isToday)
                TodayWeatherLine(
                  weather: appState.todayWeather,
                  loading: appState.loadingTodayWeather,
                )
              else if (entry?.weatherDisplayLine != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    entry!.weatherDisplayLine!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_saving ? '저장 중…' : '이 페이지 저장하기'),
            ),
          ),
        ),
          ),
          if (_saving)
            Positioned.fill(
              child: RecordSaveOverlay(
                step: _saveStep,
                complete: _saveOverlayComplete,
              ),
            ),
        ],
      ),
    );
  }

}
