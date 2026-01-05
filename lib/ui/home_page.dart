import 'package:flutter/material.dart';
import '../logic/mapping_processor.dart';
import 'widgets/mapping_drop_zone.dart';
import 'widgets/retrace_result.dart';
import 'widgets/stack_trace_input.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MappingProcessor _processor = MappingProcessor();
  String _inputText = '';
  String _outputText = '';
  bool _isProcessing = false;
  String? _mappingFileName;

  Future<void> _handleMappingLoaded(String name, String content) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _processor.loadMapping(content);
      if (!mounted) return; // 检查 widget 是否仍然挂载
      
      setState(() {
        _mappingFileName = name;
      });
      // Auto retrace if input exists
      if (_inputText.isNotEmpty) {
        _retrace();
      }
    } catch (e) {
      if (!mounted) return; // 在使用 context 之前检查
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载 mapping 文件失败: $e')),
      );
    } finally {
      if (mounted) { // finally 块中也需要检查
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleInputChange(String text) {
    _inputText = text;
    _retrace();
  }

  void _retrace() {
    if (!_processor.isLoaded) return;
    
    // In a real app, you might want to debounce this or run it in isolate too if text is huge
    final result = _processor.retrace(_inputText);
    setState(() {
      _outputText = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.android, color: Color(0xFF3DDC84)),
            SizedBox(width: 8),
            Text('De-obfuscator', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_isProcessing)
             Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                  child: SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Theme.of(context).primaryColor
                      )
                  )
              ),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive layout
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 4,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildInputColumn(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: Card(
                      child: Padding(
                         padding: const EdgeInsets.all(0), // RetraceResult handles its own padding internally or via container
                         child: RetraceResult(text: _outputText),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _buildInputColumn(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: RetraceResult(text: _outputText),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildInputColumn() {
    return Column(
      children: [
        MappingDropZone(
          onFileLoaded: _handleMappingLoaded,
          fileName: _mappingFileName,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StackTraceInput(
            onChanged: _handleInputChange,
          ),
        ),
      ],
    );
  }
}
