/// 오늘 저장하기 진행 단계 (UI 메시지용)
enum RecordSaveStep {
  preparingPhotos('장면을 정리하는 중'),
  uploadingPhotos('사진을 올리는 중'),
  writingLine('일기를 쓰는 중'),
  bindingPage('책에 붙이는 중'),
  analyzingStory('이야기를 연결하는 중');

  const RecordSaveStep(this.label);

  final String label;

  int get stepIndex => RecordSaveStep.values.indexOf(this);
}
