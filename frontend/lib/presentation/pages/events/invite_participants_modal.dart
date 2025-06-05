import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InviteParticipantsModal extends StatelessWidget {
  final List<String> nicknames;
  final VoidCallback onInviteLater;
  final String invitationLink;

  const InviteParticipantsModal({
    Key? key,
    required this.nicknames,
    required this.onInviteLater,
    required this.invitationLink,
  }) : super(key: key);

  void _shareLink(BuildContext context) {
    // Use Clipboard to copy the actual invitation link
    Clipboard.setData(ClipboardData(text: invitationLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien d\'invitation copié dans le presse-papiers'),
        backgroundColor: Color(0xFFFF5722),
      ),
    );
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
                    onPressed: onInviteLater,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFFFF5722), size: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'Ton tricount est prêt à être utilisé !',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invite tous les participants en leur envoyant un message avec le lien d\'invitation ou montre-leur un QR d\'invitation.',
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
              const Text(
                'Participants à inviter',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              ...nicknames.map((nickname) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    child: Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _shareLink(context),
                  icon: const Icon(Icons.share),
                  label: const Text(
                    'Copier le lien',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onInviteLater,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2D3142),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Inviter plus tard'),
              ),
            ],
          ),
        );
      },
    );
  }
}
