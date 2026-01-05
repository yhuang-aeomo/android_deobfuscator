import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class StackTraceInput extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const StackTraceInput({super.key, required this.onChanged});

  @override
  State<StackTraceInput> createState() => _StackTraceInputState();
}

class _StackTraceInputState extends State<StackTraceInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isDragging = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Obfuscated Stack Trace:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DropTarget(
            onDragEntered: (details) {
              setState(() {
                _isDragging = true;
              });
            },
            onDragExited: (details) {
              setState(() {
                _isDragging = false;
              });
            },
            onDragDone: (details) async {
              setState(() {
                _isDragging = false;
              });

              if (details.files.isNotEmpty) {
                final file = details.files.first;
                // Read file content
                try {
                  final bytes = await file.readAsBytes();
                  final content = utf8.decode(bytes);
                  
                  // Update text field and notify parent
                  _controller.text = content;
                  widget.onChanged(content);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loaded stack trace from ${file.name}')),
                    );
                  }
                } catch (e) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error reading file: $e')),
                    );
                  }
                }
              }
            },
            child: Container(
              decoration: _isDragging
                  ? BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Stack(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50], // Slightly darker than white for input area
                      hintText: 'Paste obfuscated stack trace here\nor Drag & Drop a log file...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace', 
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF2B2B2B)
                    ),
                    onChanged: widget.onChanged,
                  ),
                  if (_isDragging)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_upload_outlined, size: 48, color: Theme.of(context).primaryColor),
                            const SizedBox(height: 16),
                            Text(
                              "Drop file to load",
                              style: TextStyle(
                                color: Theme.of(context).primaryColor, 
                                fontWeight: FontWeight.bold,
                                fontSize: 18
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
