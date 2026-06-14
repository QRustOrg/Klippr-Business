import 'package:flutter/material.dart';

// author: Samuel Bonifacio
//
// Campo de texto reutilizado por las pantallas de la app (IAM y otras). Portado
// 1:1 desde KlipprField.kt: outlined, esquinas redondeadas (8), borde morado al
// foco, label gris e ícono "limpiar" que vacía el campo.

/// Colores propios del campo (mantienen el look 1:1 con el mockup).
const Color _fieldButtonPurple = Color(0xFF7B6AF0);
const Color _fieldBorder = Color(0xFFCAC4D0);
const Color _fieldTextGray = Color(0xFF888888);
const Color _fieldTextDark = Color(0xFF1A1A1A);
const Color _fieldClearIcon = Color(0xFF9E9E9E);

/// Campo de texto estándar de Klippr.
class KlipprField extends StatelessWidget {
  const KlipprField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final bool isPassword;
  final TextInputType keyboardType;

  /// Controlador opcional. Si no se provee, el widget gestiona uno interno
  /// sincronizado con [value].
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final effectiveController =
        controller ?? TextEditingController(text: value);
    // Mantiene el cursor al final cuando el valor externo cambia.
    if (controller == null && effectiveController.text != value) {
      effectiveController.value = effectiveController.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }

    return TextField(
      controller: effectiveController,
      onChanged: onChanged,
      obscureText: isPassword,
      keyboardType: isPassword ? TextInputType.visiblePassword : keyboardType,
      style: const TextStyle(color: _fieldTextDark),
      cursorColor: _fieldButtonPurple,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: _fieldTextGray),
        floatingLabelStyle: const TextStyle(color: _fieldButtonPurple),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          tooltip: 'Borrar',
          onPressed: () {
            effectiveController.clear();
            onChanged('');
          },
          icon: const Icon(Icons.cancel, color: _fieldClearIcon, size: 22),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _fieldBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _fieldBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: _fieldButtonPurple, width: 2),
        ),
      ),
    );
  }
}
