/// 移除文本中的 HTML 标签。
///
/// 这里只处理标签本身，不负责 HTML 实体解码或完整 HTML 清洗。
String stripHtmlTags(String value) {
  return value.replaceAll(RegExp(r'<[^>]*>'), '');
}

String formatDate(DateTime? value) {
  if (value == null) return '未知日期';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

String formatDuration(int? seconds) {
  if (seconds == null || seconds < 0) return '未知时长';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remaining = seconds % 60;
  String two(int number) => number.toString().padLeft(2, '0');
  if (hours > 0) return '$hours:${two(minutes)}:${two(remaining)}';
  return '$minutes:${two(remaining)}';
}
