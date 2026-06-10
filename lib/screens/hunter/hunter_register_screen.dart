import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/hunt_service.dart';

class HunterRegisterScreen extends StatefulWidget {
  final String huntId;
  const HunterRegisterScreen({super.key, required this.huntId});

  @override
  State<HunterRegisterScreen> createState() => _HunterRegisterScreenState();
}

class _HunterRegisterScreenState extends State<HunterRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  Uint8List? _selfieBytes;
  bool _loading = false;
  bool _checkingName = false;
  String? _suggestedName;
  Timer? _debounce;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().isEmpty) return;
      setState(() => _checkingName = true);
      final service = context.read<HuntService>();
      final taken = await service.isNameTaken(widget.huntId, value.trim());
      if (!mounted) return;
      if (taken) {
        final suggested =
            await service.suggestUniqueName(widget.huntId, value.trim());
        setState(() {
          _suggestedName = suggested;
          _checkingName = false;
        });
      } else {
        setState(() {
          _suggestedName = null;
          _checkingName = false;
        });
      }
    });
  }

  Future<void> _captureSelfie() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _selfieBytes = bytes);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selfieBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, tire uma selfie! 📸')),
      );
      return;
    }

    String name = _nameCtrl.text.trim();
    // Use suggested name if current name is taken
    if (_suggestedName != null) {
      final useSuggested = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nome já existe'),
          content: Text(
              'O nome "$name" já está em uso.\n\nQuer usar "$_suggestedName"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Mudar nome')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Usar "$_suggestedName"'),
            ),
          ],
        ),
      );
      if (useSuggested != true || !mounted) return;
      name = _suggestedName!;
    }

    setState(() => _loading = true);
    try {
      final service = context.read<HuntService>();
      final hunterId = await service.registerHunter(
        huntId: widget.huntId,
        name: name,
        selfieBytes: _selfieBytes!,
        selfieName: 'selfie_$name.jpg',
      );
      if (mounted) {
        context.go('/hunt/${widget.huntId}/waiting/$hunterId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro do Caçador 🧒'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Qual é o seu nome, aventureiro?',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Name input
              TextFormField(
                controller: _nameCtrl,
                onChanged: _onNameChanged,
                decoration: InputDecoration(
                  labelText: 'Seu nome',
                  prefixIcon: const Icon(Icons.person),
                  suffixIcon: _checkingName
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _suggestedName != null
                          ? const Icon(Icons.warning, color: Colors.orange)
                          : null,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe seu nome' : null,
              ),
              if (_suggestedName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    'Este nome já existe! Sugestão: "$_suggestedName"',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Selfie section
              const Text(
                'Tire uma selfie! 📸',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _captureSelfie,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(
                          color: const Color(0xFFFFB703), width: 3),
                    ),
                    child: _selfieBytes != null
                        ? ClipOval(
                            child: Image.memory(_selfieBytes!,
                                fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt,
                                  size: 48,
                                  color: Color(0xFFFFB703)),
                              SizedBox(height: 8),
                              Text('Tocar para tirar\na selfie',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text('Entrar na Caçada!'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
