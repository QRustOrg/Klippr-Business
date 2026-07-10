import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/presentation/views/promo_colors.dart';
import '../../application/bloc/profile_bloc.dart';
import '../../application/bloc/profile_event.dart';
import '../../application/bloc/profile_state.dart';
import '../../domain/models/business_profile_update.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _categories = {
    'RESTAURANT': 'Restaurante',
    'RETAIL': 'Comercio',
    'SERVICES': 'Servicios',
    'ENTERTAINMENT': 'Entretenimiento',
    'HEALTH': 'Salud',
    'OTHER': 'Otros',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _country;
  late final TextEditingController _zip;
  late String _category;
  late bool _hadLocation;
  String _profileId = '';
  String? _locationError;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileBloc>().state.profile;
    _profileId = profile?.id.value ?? '';
    _name = TextEditingController(text: profile?.businessName ?? '');
    final category = profile?.category?.name?.toUpperCase();
    _category = _categories.containsKey(category) ? category! : 'OTHER';
    _description = TextEditingController(text: profile?.description ?? '');
    _street = TextEditingController(text: profile?.location?.street ?? '');
    _city = TextEditingController(text: profile?.location?.city ?? '');
    _state = TextEditingController(text: profile?.location?.state ?? '');
    _country = TextEditingController(text: profile?.location?.country ?? '');
    _zip = TextEditingController(text: profile?.location?.postalCode ?? '');
    _hadLocation = profile?.location != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _zip.dispose();
    super.dispose();
  }

  void _save() {
    if (_profileId.isEmpty || !_formKey.currentState!.validate()) return;
    final location = [
      _street.text.trim(),
      _city.text.trim(),
      _state.text.trim(),
      _country.text.trim(),
      _zip.text.trim(),
    ];
    final anyLocation = location.any((value) => value.isNotEmpty);
    final completeLocation = location.every((value) => value.isNotEmpty);
    if (anyLocation && !completeLocation) {
      setState(
        () => _locationError = 'Completa todos los campos de ubicación.',
      );
      return;
    }
    if (_hadLocation && !anyLocation) {
      setState(
        () => _locationError = 'La ubicación existente no se puede eliminar.',
      );
      return;
    }
    setState(() => _locationError = null);
    context.read<ProfileBloc>().add(
      UpdateBusinessProfileRequested(
        BusinessProfileUpdate(
          profileId: _profileId,
          businessName: _name.text.trim(),
          category: _category,
          description: _description.text.trim(),
          street: anyLocation ? location[0] : null,
          city: anyLocation ? location[1] : null,
          state: anyLocation ? location[2] : null,
          country: anyLocation ? location[3] : null,
          zipCode: anyLocation ? location[4] : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PromoColors.purple,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Editar perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.actionMessage != null) Navigator.of(context).maybePop();
        },
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _Field(
                  fieldKey: const Key('profile-name'),
                  label: 'Nombre comercial',
                  controller: _name,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre comercial.'
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DropdownButtonFormField<String>(
                    key: const Key('profile-category'),
                    initialValue: _category,
                    decoration: _decoration('Categoría'),
                    items: _categories.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: state.isSaving
                        ? null
                        : (value) => setState(() => _category = value!),
                    validator: (value) =>
                        value == null ? 'Selecciona una categoría.' : null,
                  ),
                ),
                _Field(
                  fieldKey: const Key('profile-description'),
                  label: 'Descripción',
                  controller: _description,
                  maxLines: 3,
                ),
                _Field(
                  fieldKey: const Key('profile-street'),
                  label: 'Dirección',
                  controller: _street,
                ),
                _Field(
                  fieldKey: const Key('profile-city'),
                  label: 'Ciudad',
                  controller: _city,
                ),
                _Field(
                  fieldKey: const Key('profile-state'),
                  label: 'Estado',
                  controller: _state,
                ),
                _Field(
                  fieldKey: const Key('profile-country'),
                  label: 'País',
                  controller: _country,
                ),
                _Field(
                  fieldKey: const Key('profile-zip'),
                  label: 'Código postal',
                  controller: _zip,
                ),
                if (_locationError != null) _ErrorText(_locationError!),
                if (state.error != null) _ErrorText(state.error!),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('save-profile'),
                    onPressed: state.isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PromoColors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: state.isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Guardar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.validator,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: fieldKey,
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: _decoration(label),
    ),
  );
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: PromoColors.fieldBg,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: PromoColors.purple),
  ),
);
