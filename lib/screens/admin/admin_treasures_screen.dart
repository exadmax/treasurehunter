import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/treasure.dart';
import '../../services/hunt_service.dart';

class AdminTreasuresScreen extends StatefulWidget {
  final String huntId;
  const AdminTreasuresScreen({super.key, required this.huntId});

  @override
  State<AdminTreasuresScreen> createState() => _AdminTreasuresScreenState();
}

/// Returns true if the given treasure count qualifies for starting the hunt
/// (must be a positive odd number).
bool _canStartHunt(int count) => count > 0 && count % 2 != 0;

class _AdminTreasuresScreenState extends State<AdminTreasuresScreen> {
  @override
  Widget build(BuildContext context) {
    final service = context.read<HuntService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tesouros 💎'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/setup'),
        ),
        actions: [
          StreamBuilder<List<Treasure>>(
            stream: service.watchTreasures(widget.huntId),
            builder: (context, snap) {
              final treasures = snap.data ?? [];
              final count = treasures.length;
              final isOdd = _canStartHunt(count);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  onPressed: isOdd
                      ? () => context.go('/admin/lobby/${widget.huntId}')
                      : null,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Iniciar'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isOdd ? const Color(0xFF023047) : Colors.grey,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Treasure>>(
        stream: service.watchTreasures(widget.huntId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final treasures = snap.data ?? [];
          final count = treasures.length;
          final isOdd = _canStartHunt(count);

          return Column(
            children: [
              _buildCountBanner(context, count, isOdd),
              Expanded(
                child: treasures.isEmpty
                    ? const Center(
                        child: Text('Nenhum tesouro cadastrado ainda.\n'
                            'Adicione pelo menos 1 tesouro ímpar para começar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: treasures.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _TreasureListTile(
                          treasure: treasures[i],
                          huntId: widget.huntId,
                          service: service,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTreasureDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Tesouro'),
        backgroundColor: const Color(0xFFFFB703),
        foregroundColor: const Color(0xFF023047),
      ),
    );
  }

  Widget _buildCountBanner(BuildContext context, int count, bool isOdd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: isOdd
          ? Colors.green.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            isOdd ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isOdd ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count == 0
                  ? 'Cadastre um número ímpar de tesouros para iniciar.'
                  : isOdd
                      ? '$count tesouros cadastrados ✓  (número ímpar — pode iniciar!)'
                      : '$count tesouros cadastrados — adicione mais 1 para ter número ímpar.',
              style: TextStyle(
                color: isOdd ? Colors.green[800] : Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTreasureDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddTreasureSheet(huntId: widget.huntId),
    );
  }
}

class _TreasureListTile extends StatelessWidget {
  final Treasure treasure;
  final String huntId;
  final HuntService service;

  const _TreasureListTile({
    required this.treasure,
    required this.huntId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: treasure.imageUrl != null
              ? Image.network(
                  treasure.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 40),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.amber[100],
                  child:
                      const Icon(Icons.diamond, color: Color(0xFFFFB703))),
        ),
        title: Text(treasure.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => _showQrCode(context, treasure),
              tooltip: 'Ver QR Code',
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () =>
                  _confirmDelete(context, treasure, huntId, service),
              tooltip: 'Remover',
            ),
          ],
        ),
      ),
    );
  }

  void _showQrCode(BuildContext context, Treasure treasure) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(treasure.name),
        content: SizedBox(
          width: 220,
          height: 220,
          child: Center(
            child: QrImageView(
              data: treasure.id,
              version: QrVersions.auto,
              size: 200,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Treasure treasure, String huntId,
      HuntService service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover Tesouro'),
        content: Text('Deseja remover "${treasure.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteTreasure(huntId, treasure.id);
            },
            child: const Text('Remover',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddTreasureSheet extends StatefulWidget {
  final String huntId;
  const _AddTreasureSheet({required this.huntId});

  @override
  State<_AddTreasureSheet> createState() => _AddTreasureSheetState();
}

class _AddTreasureSheetState extends State<_AddTreasureSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final service = context.read<HuntService>();
      await service.addTreasure(
        huntId: widget.huntId,
        name: _nameCtrl.text.trim(),
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Novo Tesouro',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Tesouro',
                prefixIcon: Icon(Icons.diamond),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 16),
            // Image picker
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ImagePickerButton(
                            icon: Icons.photo_library,
                            label: 'Galeria',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                          _ImagePickerButton(
                            icon: Icons.camera_alt,
                            label: 'Câmera',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.grey),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
