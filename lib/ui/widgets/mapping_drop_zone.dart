import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class MappingDropZone extends StatefulWidget {
  final Function(String name, String content) onFileLoaded;
  final String? fileName;

  const MappingDropZone({
    super.key,
    required this.onFileLoaded,
    this.fileName,
  });

  @override
  State<MappingDropZone> createState() => _MappingDropZoneState();
}

class _MappingDropZoneState extends State<MappingDropZone> {
  bool _isDragging = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true, // Needed for web
    );

    if (result != null) {
      final file = result.files.first;
      final content = utf8.decode(file.bytes!);
      widget.onFileLoaded(file.name, content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
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
          // Note: readAsBytes is available on CrossFile
          final bytes = await file.readAsBytes();
          final content = utf8.decode(bytes);
          widget.onFileLoaded(file.name, content);
        }
      },
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isDragging 
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
                : widget.fileName != null ? Colors.green.withValues(alpha: 0.05) : Colors.grey[50],
            border: Border.all(
              color: _isDragging 
                  ? Theme.of(context).primaryColor 
                  : widget.fileName != null ? Colors.green : Colors.grey.shade300,
              style: BorderStyle.solid,
              width: _isDragging ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.fileName != null ? Icons.description : Icons.cloud_upload_outlined,
                size: 32,
                color: widget.fileName != null ? Colors.green : Colors.grey[600],
              ),
              const SizedBox(height: 8),
              if (widget.fileName != null)
                 Text(
                   widget.fileName!,
                   style: const TextStyle(
                     color: Colors.green,
                     fontWeight: FontWeight.w600,
                     fontSize: 16,
                   ),
                 )
              else
                 Text(
                  'Drag & Drop mapping.txt here',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              if (widget.fileName == null)
                Text(
                  'or click to browse',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
