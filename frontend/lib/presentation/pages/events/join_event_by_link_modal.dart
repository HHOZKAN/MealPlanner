import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/event_participants_provider.dart';
import '../../../presentation/providers/auth_provider.dart';

class JoinEventByLinkModal extends ConsumerStatefulWidget {
  final VoidCallback onCancel;

  const JoinEventByLinkModal({Key? key, required this.onCancel}) : super(key: key);

  @override
  ConsumerState<JoinEventByLinkModal> createState() => _JoinEventByLinkModalState();
}

class _JoinEventByLinkModalState extends ConsumerState<JoinEventByLinkModal> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _linkController.text = clipboardData.text!;
      });
    }
  }

  Future<void> _joinEvent() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid link'),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract token from link (assuming token is a query param named 'token')
      Uri uri = Uri.parse(link);
      String? token = uri.queryParameters['token'];
      if (token == null || token.isEmpty) {
        throw Exception('Invalid link: missing token');
      }

      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.post(
        ApiConstants.eventParticipantAcceptInvitation,
        data: {'token': token},
      );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation accepted successfully'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          // Navigate to event detail page after successful join
          String? eventIdStr = uri.queryParameters['event_id'];
          if (eventIdStr != null && eventIdStr.isNotEmpty) {
            final eventId = int.tryParse(eventIdStr);
            if (eventId != null) {
              // Refresh events list and participant count in dashboard
              ref.read(eventsStateProvider.notifier).loadEvents();
              ref.invalidate(participantCountProvider(eventId));
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/events/$eventId');
              return;
            }
          }
          // Fallback if eventId is not valid
          ref.read(eventsStateProvider.notifier).loadEvents();
          Navigator.of(context).pop();
        }
    } on DioException catch (e) {
      String errorMessage = e.response?.data?['message'] ?? 'Error accepting invitation';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F5F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFFF5722)),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.link, size: 48, color: Color(0xFFFF5722)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Join a tricount',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask other participants for the link to the event you want to join. Then, '
                      'simply click on that link.\n\n'
                      'If you prefer, you can also copy and paste it in this field.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF2D3142).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        hintText: 'Paste the link here',
                        hintStyle: TextStyle(
                          color: const Color(0xFF2D3142).withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFFFF5722)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _pasteFromClipboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.paste),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _joinEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Join',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
