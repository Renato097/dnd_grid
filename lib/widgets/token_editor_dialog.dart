import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/map_state.dart';

class TokenEditorDialog extends StatefulWidget {
  final String tokenId;
  const TokenEditorDialog({super.key, required this.tokenId});

  @override
  State<TokenEditorDialog> createState() => _TokenEditorDialogState();
}

class _TokenEditorDialogState extends State<TokenEditorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TokenCategory _category;
  late TokenSize _size;

  @override
  void initState() {
    super.initState();
    final map = context.read<MapState>();
    final token = map.tokens.firstWhere((t) => t.id == widget.tokenId);
    _nameController = TextEditingController(text: token.name);
    _descController = TextEditingController(text: token.description);
    _category = token.category;
    _size = TokenSize.values.firstWhere(
      (s) => s.cells == token.sizeCells,
      orElse: () => TokenSize.medium,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = context.read<MapState>();

    return AlertDialog(
      title: const Text('Modifica pedina'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrizione breve',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Categoria', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TokenCategory.values.map((cat) {
                return ChoiceChip(
                  avatar: Icon(cat.icon, size: 16),
                  label: Text(cat.label),
                  selected: _category == cat,
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Taglia (D&D 5e)', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TokenSize.values.map((size) {
                return ChoiceChip(
                  label: Text('${size.label} (${size.cells}×${size.cells})'),
                  selected: _size == size,
                  onSelected: (_) => setState(() => _size = size),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          label: const Text('Elimina', style: TextStyle(color: Colors.redAccent)),
          onPressed: () {
            map.removeToken(widget.tokenId);
            Navigator.of(context).pop();
          },
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            map.updateTokenInfo(
              widget.tokenId,
              name: _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
              description: _descController.text.trim(),
              category: _category,
              size: _size,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}