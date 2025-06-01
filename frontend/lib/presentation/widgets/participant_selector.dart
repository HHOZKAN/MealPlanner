import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParticipantSelector extends ConsumerStatefulWidget {
  final List<String> selectedNicknames;
  final Function(List<String>) onParticipantsChanged;
  final String? title;
  final String? subtitle;

  const ParticipantSelector({
    Key? key,
    required this.selectedNicknames,
    required this.onParticipantsChanged,
    this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  ConsumerState<ParticipantSelector> createState() => _ParticipantSelectorState();
}

class _ParticipantSelectorState extends ConsumerState<ParticipantSelector> {
  final TextEditingController _nicknameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<String> _nicknames = [];

  @override
  void initState() {
    super.initState();
    _nicknames = List.from(widget.selectedNicknames);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool _isValidNickname(String nickname) {
    return nickname.length >= 2 && nickname.length <= 30;
  }

  void _addNickname() {
    if (_formKey.currentState!.validate()) {
      final nickname = _nicknameController.text.trim();
      if (!_nicknames.contains(nickname)) {
        setState(() {
          _nicknames.add(nickname);
          _nicknameController.clear();
        });
        widget.onParticipantsChanged(_nicknames);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce pseudo est déjà ajouté'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeNickname(String nickname) {
    setState(() {
      _nicknames.remove(nickname);
    });
    widget.onParticipantsChanged(_nicknames);
  }

  void _showAddParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Ajouter un participant',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nicknameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Prénom ou pseudo',
                  labelStyle: const TextStyle(color: Color(0xFF2D3142)),
                  hintText: 'Ex: Jean, Marie, Alex...',
                  prefixIcon: const Icon(Icons.person, color: Color(0xFFFF5722)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF5722)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prénom ou pseudo';
                  }
                  if (!_isValidNickname(value)) {
                    return 'Le prénom doit faire entre 2 et 30 caractères';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _addNickname(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nicknameController.clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _addNickname();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ajouter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? 'Participants',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: _showAddParticipantDialog,
                  icon: const Icon(
                    Icons.person_add,
                    color: Color(0xFFFF5722),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Participants list
            if (_nicknames.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun participant ajouté',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appuyez sur + pour ajouter des participants',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _nicknames.map((nickname) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF5722).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            nickname[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nickname,
                          style: const TextStyle(
                            color: Color(0xFF2D3142),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeNickname(nickname),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFFF5722),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                )).toList(),
              ),
            
            // Summary
            if (_nicknames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_nicknames.length} participant${_nicknames.length > 1 ? 's' : ''} ajouté${_nicknames.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
