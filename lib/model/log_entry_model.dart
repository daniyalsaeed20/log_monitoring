class LogEntry {
  String line;
  String timestamp;
  String userId;

  LogEntry({
    required this.line,
    required this.timestamp,
    required this.userId,
  });
  
  Map<String, dynamic> toJson() => {
        'line': line,
        'timestamp': timestamp,
        'userId': userId,
      };
      
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      line: json['line'],
      timestamp: json['timestamp'],
      userId: json['userId'],
    );
  }
}
