import 'package:flutter/material.dart';

class GeneInfoCard extends StatelessWidget {
  final String? geneMarker;
  final VoidCallback onUploadReport;

  const GeneInfoCard({Key? key, this.geneMarker, required this.onUploadReport})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: geneMarker != null ? Colors.red.shade50 : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color:
                      geneMarker != null
                          ? const Color(0xFFCC1C14)
                          : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Genetic Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        geneMarker != null
                            ? const Color(0xFFCC1C14)
                            : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            geneMarker != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Gene Marker:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      geneMarker!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFCC1C14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your nutrition recommendations are personalized based on your genetic profile.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No genetic data available',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload your genetic report to receive personalized nutrition recommendations based on your DNA.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onUploadReport,
                style: TextButton.styleFrom(
                  backgroundColor:
                      geneMarker != null
                          ? Colors.white
                          : const Color(0xFFCC1C14),
                  foregroundColor:
                      geneMarker != null
                          ? const Color(0xFFCC1C14)
                          : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side:
                        geneMarker != null
                            ? const BorderSide(color: Color(0xFFCC1C14))
                            : BorderSide.none,
                  ),
                ),
                child: Text(
                  geneMarker != null
                      ? 'Update Genetic Report'
                      : 'Upload Genetic Report',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
