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
    // Example: 
    //     10:20:void method():30:40 -> a
    //     void method() -> a
    //     int field -> b
    
    final trimmed = line.trim();
    if (!trimmed.contains(' -> ')) return;

    final parts = trimmed.split(' -> ');
    final leftSide = parts[0];
    final obfuscatedName = parts[1];

    // Check if it's a method with line numbers
    // Regex for method with line numbers: start:end:returntype name(args):orig_start:orig_end
    // Simpler check: contains ':'
    
    if (leftSide.contains('(')) {
       // Method
       // TODO: Implement precise method parsing
       // For now, just a simple storage
       classInfo.addMethod(obfuscatedName, MethodInfo(originalName: leftSide)); // Simplification
    } else {
      // Field
      classInfo.addField(obfuscatedName, leftSide);
    }
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
        // Note: lineNumber can be used in the future for precise method matching
        // final lineNumberStr = match.group(4);
        // final lineNumber = lineNumberStr != null ? int.tryParse(lineNumberStr) : -1;

        final classInfo = _map!.getClass(obfuscatedClass);
        if (classInfo != null) {
          String newClass = classInfo.originalName;
          String newMethod = obfuscatedMethod;
          
          // Try to find method
          // This is a simplified lookup. A real retrace needs to handle line numbers strictly.
          if (classInfo.methods.containsKey(obfuscatedMethod)) {
             final methodInfos = classInfo.methods[obfuscatedMethod]!;
             // For now pick the first one or logic to match line numbers
             if (methodInfos.isNotEmpty) {
               // Extract clean method name from signature "10:20:void method()"
               // This requires better parsing in _parseMember. 
               // Placeholder logic:
               newMethod = methodInfos.first.originalName; 
             }
          }
          
          // Reconstruct the line
          // Replace obfuscatedClass with newClass
          // Replace obfuscatedMethod with newMethod
          // For now, simple string replacement in the line for visual confirmation
          String newLine = line.replaceFirst(obfuscatedClass, newClass).replaceFirst(obfuscatedMethod, newMethod);
          buffer.writeln(newLine);
        } else {
          buffer.writeln(line);
        }
      } else {
        buffer.writeln(line);
      }
    }
    return buffer.toString();
  }
}
