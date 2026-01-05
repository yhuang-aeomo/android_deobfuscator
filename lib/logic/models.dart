class ObfuscatedMap {
  // Key: Obfuscated class name (e.g., "a.b.c")
  // Value: Original class info
  final Map<String, ClassInfo> classes = {};

  void addClass(String obfuscatedName, String originalName) {
    classes[obfuscatedName] = ClassInfo(originalName);
  }

  ClassInfo? getClass(String obfuscatedName) {
    return classes[obfuscatedName];
  }
}

class ClassInfo {
  final String originalName;
  // Key: Obfuscated method name
  // Value: List of method info (to handle overloads or line number ranges)
  final Map<String, List<MethodInfo>> methods = {};
  
  // Key: Obfuscated field name
  // Value: Original field name
  final Map<String, String> fields = {};

  ClassInfo(this.originalName);

  void addMethod(String obfuscatedName, MethodInfo info) {
    methods.putIfAbsent(obfuscatedName, () => []).add(info);
  }
  
  void addField(String obfuscatedName, String originalName) {
    fields[obfuscatedName] = originalName;
  }
}

class MethodInfo {
  final String originalName;
  final int startLine; // Obfuscated start line
  final int endLine;   // Obfuscated end line
  final int originalStartLine; // Original start line
  final int originalEndLine;   // Original end line
  final String signature; // Optional: method signature if available

  MethodInfo({
    required this.originalName,
    this.startLine = -1,
    this.endLine = -1,
    this.originalStartLine = -1,
    this.originalEndLine = -1,
    this.signature = "",
  });
  
  bool matches(int line) {
    if (startLine == -1 || endLine == -1) return true; // Loose match if no line info
    return line >= startLine && line <= endLine;
  }
}
