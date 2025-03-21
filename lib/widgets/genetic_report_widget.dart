import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:nutrigen/services/profile_service.dart';

class GeneticReportWidget extends StatefulWidget {
  final String? geneticReportFile;
  final String? geneMarker;
  final Function(PlatformFile) onReportPicked;
  final Function(String?) onGeneMarkerUpdated;
  final bool isProcessing;

  const GeneticReportWidget({
    Key? key,
    this.geneticReportFile,
    this.geneMarker,
    required this.onReportPicked,
    required this.onGeneMarkerUpdated,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  State<GeneticReportWidget> createState() => _GeneticReportWidgetState();
}

class _GeneticReportWidgetState extends State<GeneticReportWidget> {
  String? _fileName;
  final ProfileService _profileService = ProfileService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fileName = widget.geneticReportFile;
    _isProcessing = widget.isProcessing;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true, // Important for web - ensure we get the bytes
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fileName = result.files.first.name;
        _isProcessing = true;
      });

      // Call the callback to notify parent - pass the PlatformFile directly
      widget.onReportPicked(result.files.first);

      try {
        // Process the file to extract gene marker
        final response = await _profileService.processGeneticReport(
          result.files.first,
        );

        if (response['success'] == true) {
          final geneMarker = response['data']['geneMarker'];

          // Call the callback to update the gene marker
          widget.onGeneMarkerUpdated(geneMarker);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  geneMarker != null
                      ? 'Genetic report processed successfully. Gene marker: $geneMarker'
                      : 'Genetic report processed, but no gene marker was found.',
                ),
                backgroundColor:
                    geneMarker != null ? Colors.green : Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error processing genetic report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Your Genetic Analysis Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload a genetic analysis report (PDF, DOCX, JPG, PNG). We\'ll analyze it to personalize your nutrition plan.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isProcessing ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fileName ?? 'Select a file',
                    style: TextStyle(
                      color:
                          _fileName != null ? Colors.black : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFCC1C14),
                      ),
                    ),
                  )
                else
                  const Icon(Icons.file_download_outlined),
              ],
            ),
          ),
        ),

        // Show gene marker if available
        if (widget.geneMarker != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: Color(0xFFCC1C14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gene Marker Detected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCC1C14),
                        ),
                      ),
                      Text(
                        'Your detected gene marker: ${widget.geneMarker}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This gene will be used to personalize your nutrition recommendations.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
