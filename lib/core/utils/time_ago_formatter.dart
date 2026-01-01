class TimeAgoFormatter {
  static String format(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);

    if (duration.inSeconds < 60) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h';
    } else if (duration.inDays < 7) {
      return '${duration.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}