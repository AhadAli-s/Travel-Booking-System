import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

/// Screen 12: confirmation, tickets, vouchers, insurance, visa, ATOL, invoice and receipts.
/// Files open through a short lived signed link, so the login token is never put in a URL.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    required this.bookingId,
    this.guest = false,
    this.guestDocuments = const <TravelDocument>[],
  });

  final int bookingId;
  final bool guest;
  final List<TravelDocument> guestDocuments;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late final BookingService _service;
  late Future<List<TravelDocument>> _future;
  int? _openingId;

  @override
  void initState() {
    super.initState();
    _service = BookingService(context.read<ApiClient>());
    _future = _load();
  }

  Future<List<TravelDocument>> _load() {
    if (widget.guest) return Future<List<TravelDocument>>.value(widget.guestDocuments);
    return _service.documents(widget.bookingId);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(TravelDocument document) async {
    setState(() => _openingId = document.id);
    try {
      final uri = await _service.documentLink(document.id);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) _message('Could not open the document.');
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    } catch (_) {
      if (mounted) _message('Could not open the document.');
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text('Travel documents', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<TravelDocument>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.pink));
          }
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _refresh);
          }
          final documents = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.pink,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      children: [
                        if (widget.guest && documents.isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.yellowTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Log in to view and download your documents.',
                              style: TextStyle(fontSize: 13, color: AppColors.ink),
                            ),
                          ),
                        if (documents.isEmpty)
                          const EmptyState(
                            icon: Icons.description_outlined,
                            title: 'No documents yet',
                            message: 'Your tickets, vouchers and invoice appear here when the agency issues them.',
                          )
                        else
                          for (final document in documents) ...[
                            _DocumentTile(
                              document: document,
                              locked: widget.guest,
                              opening: _openingId == document.id,
                              onOpen: () => _open(document),
                            ),
                            const SizedBox(height: 10),
                          ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'BookingConfirmation':
      return Icons.confirmation_number_outlined;
    case 'FlightTickets':
      return Icons.flight;
    case 'HotelVoucher':
      return Icons.hotel_outlined;
    case 'TransferVoucher':
      return Icons.airport_shuttle_outlined;
    case 'TravelInsurance':
      return Icons.health_and_safety_outlined;
    case 'VisaDocuments':
      return Icons.badge_outlined;
    case 'ATOLCertificate':
      return Icons.verified_user_outlined;
    case 'Invoice':
      return Icons.receipt_long_outlined;
    case 'PaymentReceipt':
      return Icons.receipt_outlined;
    default:
      return Icons.description_outlined;
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.locked,
    required this.opening,
    required this.onOpen,
  });

  final TravelDocument document;
  final bool locked;
  final bool opening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: (locked || opening) ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cyanTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(document.documentType), color: AppColors.cyanDark, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentTypeLabel(document.documentType),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${document.fileName}  |  ${formatDate(document.uploadedAt?.toLocal())}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (locked)
                const Icon(Icons.lock_outline, color: AppColors.muted)
              else if (opening)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pink),
                )
              else
                const Icon(Icons.open_in_new, color: AppColors.pink),
            ],
          ),
        ),
      ),
    );
  }
}