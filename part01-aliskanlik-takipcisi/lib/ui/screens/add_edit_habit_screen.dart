import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/habit_repository.dart';
import '../theme/app_theme.dart';

class AddEditHabitScreen extends StatefulWidget {
  const AddEditHabitScreen({super.key, required this.repository, this.habit});

  final HabitRepository repository;

  /// null ise "ekle" modu, doluysa "düzenle" modu.
  final Habit? habit;

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  late final TextEditingController _nameController;
  late final ValueNotifier<Color> _selectedColor;
  String? _nameError;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _selectedColor = ValueNotifier(
      widget.habit != null
          ? Color(widget.habit!.colorValue)
          : AppColors.habitPalette.first,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _selectedColor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Bir isim gerekli');
      return;
    }

    if (_isEditing) {
      await widget.repository.updateHabit(
        habitId: widget.habit!.id,
        name: name,
        colorValue: _selectedColor.value.toARGB32(),
      );
    } else {
      await widget.repository.addHabit(
        name: name,
        colorValue: _selectedColor.value.toARGB32(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text('Alışkanlığı sil?'),
        content: Text(
          '"${widget.habit!.name}" ve tüm işaretli günleri kalıcı olarak silinecek.',
          style: AppTextStyles.rowSubtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await widget.repository.deleteHabit(widget.habit!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Alışkanlığı düzenle' : 'Yeni alışkanlık',
          style: AppTextStyles.h1.copyWith(fontSize: 19),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.text),
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              style: AppTextStyles.rowTitle,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                hintText: 'ör. Su iç',
                hintStyle: AppTextStyles.rowSubtitle,
                errorText: _nameError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('RENK', style: AppTextStyles.cardHeader),
            const SizedBox(height: 12),
            ValueListenableBuilder<Color>(
              valueListenable: _selectedColor,
              builder: (context, selected, _) {
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: AppColors.habitPalette.map((color) {
                    final isSelected = color.toARGB32() == selected.toARGB32();
                    return GestureDetector(
                      onTap: () => _selectedColor.value = color,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: isSelected
                              ? Border.all(color: AppColors.text, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
                child: Text(_isEditing ? 'Kaydet' : 'Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
