import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'models.dart';

class MappingProcessor {
  ObfuscatedMap? _map;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads and parses the mapping file content in a background isolate.
  Future<void> loadMapping(String content) async {
    _map = await compute(_parseMappingIsolate, content);
    _isLoaded = true;
  }

  /// The actual parsing logic that runs in an isolate.
  static ObfuscatedMap _parseMappingIsolate(String content) {
    final map = ObfuscatedMap();
    final lines = LineSplitter.split(content);
    
    ClassInfo? currentClass;

    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;

      if (!line.startsWith(' ')) {
        // It's a class mapping: com.example.MyActivity -> a.b.c:
        final parts = line.split(' -> ');
        if (parts.length == 2 && parts[1].endsWith(':')) {
          final originalName = parts[0];
          final obfuscatedName = parts[1].substring(0, parts[1].length - 1);
          
          map.addClass(obfuscatedName, originalName);
          currentClass = map.getClass(obfuscatedName);
        }
      } else if (currentClass != null) {
        // It's a member mapping
        _parseMember(line, currentClass);
      }
    }
    
    return map;
  }

  static void _parseMember(String line, ClassInfo classInfo) {
    // Example formats:
    //     10:20:void method():30:40 -> a
    //     void method() -> a
    //     int field -> b
    
    final trimmed = line.trim();
    if (!trimmed.contains(' -> ')) return;

    final parts = trimmed.split(' -> ');
    if (parts.length != 2) return;
    
    final leftSide = parts[0];
    final obfuscatedName = parts[1];

    // Check if it's a method (contains parentheses)
    if (leftSide.contains('(')) {
      _parseMethod(leftSide, obfuscatedName, classInfo);
    } else {
      // Field
      classInfo.addField(obfuscatedName, leftSide);
    }
  }

  static void _parseMethod(String leftSide, String obfuscatedName, ClassInfo classInfo) {
    // Parse method with or without line numbers
    // Format 1: 10:20:void method():30:40
    // Format 2: void method()
    
    int startLine = -1;
    int endLine = -1;
    int originalStartLine = -1;
    int originalEndLine = -1;
    String methodSignature = leftSide;

    // Check if it has line number mapping
    final lineNumberPattern = RegExp(r'^(\d+):(\d+):(.+):(\d+):(\d+)$');
    final simpleLinePattern = RegExp(r'^(\d+):(\d+):(.+)$');
    
    final lineMatch = lineNumberPattern.firstMatch(leftSide);
    if (lineMatch != null) {
      // Format: 10:20:void method():30:40
      startLine = int.parse(lineMatch.group(1)!);
      endLine = int.parse(lineMatch.group(2)!);
      methodSignature = lineMatch.group(3)!;
      originalStartLine = int.parse(lineMatch.group(4)!);
      originalEndLine = int.parse(lineMatch.group(5)!);
    } else {
      // Try simple line pattern: 10:20:void method()
      final simpleMatch = simpleLinePattern.firstMatch(leftSide);
      if (simpleMatch != null) {
        startLine = int.parse(simpleMatch.group(1)!);
        endLine = int.parse(simpleMatch.group(2)!);
        methodSignature = simpleMatch.group(3)!;
      }
    }

    // Extract the method name from signature (e.g., "void method()" -> "method()")
    // Handle different formats like:
    // - "void method()"
    // - "int method(String)"
    // - "com.example.Type method(int,String)"
    final methodNameMatch = RegExp(r'(\S+)\s+([a-zA-Z0-9_$<>]+\(.*?\))').firstMatch(methodSignature);
    String cleanMethodName = methodSignature;
    
    if (methodNameMatch != null) {
      final returnType = methodNameMatch.group(1)!;
      final methodNameAndParams = methodNameMatch.group(2)!;
      cleanMethodName = '$returnType $methodNameAndParams';
    }

    classInfo.addMethod(
      obfuscatedName,
      MethodInfo(
        originalName: cleanMethodName,
        startLine: startLine,
        endLine: endLine,
        originalStartLine: originalStartLine,
        originalEndLine: originalEndLine,
        signature: methodSignature,
      ),
    );
  }

  /// Retraces a stack trace text.
  String retrace(String stackTrace) {
    if (!_isLoaded || _map == null) return stackTrace;

    final buffer = StringBuffer();
    final lines = LineSplitter.split(stackTrace);

    // Regex to capture: at package.class.method(file:line)
    // Adjust regex to match standard Android/Java stack traces
    final regExp = RegExp(r"at\s+([a-zA-Z0-9_$.]+)\.([a-zA-Z0-9_$<>]+)\(.*?(:(\d+))?\)");

    for (final line in lines) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final obfuscatedClass = match.group(1)!;
        final obfuscatedMethod = match.group(2)!;
        final lineNumberStr = match.group(4);
        final lineNumber = lineNumberStr != null ? int.tryParse(lineNumberStr) : null;

        final classInfo = _map!.getClass(obfuscatedClass);
        if (classInfo != null) {
          String newClass = classInfo.originalName;
          String newMethod = obfuscatedMethod;
          
          // Try to find the method using line number for precise matching
          if (classInfo.methods.containsKey(obfuscatedMethod)) {
            final methodInfos = classInfo.methods[obfuscatedMethod]!;
            
            MethodInfo? selectedMethod;
            
            // If we have a line number, try to match it with method line ranges
            if (lineNumber != null && lineNumber > 0) {
              for (final methodInfo in methodInfos) {
                if (methodInfo.matches(lineNumber)) {
                  selectedMethod = methodInfo;
                  break;
                }
              }
            }
            
            // Fallback to the first method if no line number match or no line number
            selectedMethod ??= methodInfos.firstOrNull;
            
            if (selectedMethod != null) {
              newMethod = selectedMethod.originalName;
            }
          }
          
          // Reconstruct the line by replacing the obfuscated names
          String newLine = line
              .replaceFirst(obfuscatedClass, newClass)
              .replaceFirst(obfuscatedMethod, newMethod);
          buffer.writeln(newLine);
        } else {
          buffer.writeln(line);
        }
      } else {
        // Not a stack trace line, just copy it
        buffer.writeln(line);
      }
    }
    return buffer.toString();
  }
}
