import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/admin_meta.dart';
import '../core/api_client.dart';
import '../core/format.dart';
import '../services/admin_document_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

/// Pick a file and upload it as a travel document. Returns true if uploaded.
Future<bool?> showUploadDocumentDialog(
  BuildContext context,
  AdminDocumentService service,
  int bookingId,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        _UploadDocumentDialog(service: service, bookingId: bookingId),
  );
}

class _UploadDocumentDialog extends StatefulWidget {
  const _UploadDocumentDialog({required this.service, required this.bookingId});

  final AdminDocumentService service;
  final int bookingId;

  @override
  State<_UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<_UploadDocumentDialog> {
  String _documentType = documentTypes.first;
  PlatformFile? _file;
  bool _loading = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = result.files.first;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    final file = _file;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      setState(() => _error = 'Choose a file to upload');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.upload(
        bookingId: widget.bookingId,
        documentType: _documentType,
        bytes: bytes,
        fileName: file.name,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload document'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              decoration: const InputDecoration(labelText: 'Document type'),
              items: [
                for (final t in documentTypes)
                  DropdownMenuItem(value: t, child: Text(documentTypeLabel(t))),
              ],
              onChanged: (value) =>
                  setState(() => _documentType = value ?? _documentType),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: Icon(documentTypeIcon(_documentType)),
              label: Text(
                _file == null ? 'Choose file (PDF, PNG, JPEG)' : _file!.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 110,
          child: PrimaryButton(
            label: 'Upload',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
