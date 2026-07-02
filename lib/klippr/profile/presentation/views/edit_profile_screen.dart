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
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _country;
  late final TextEditingController _zip;
  String _profileId = '';

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileBloc>().state.profile;
    _profileId = profile?.id.value ?? '';
    _name = TextEditingController(text: profile?.businessName ?? '');
    _category = TextEditingController(text: profile?.category?.name ?? '');
    _description = TextEditingController(text: profile?.description ?? '');
    _street = TextEditingController(text: profile?.location?.street ?? '');
    _city = TextEditingController(text: profile?.location?.city ?? '');
    _state = TextEditingController(text: profile?.location?.state ?? '');
    _country = TextEditingController(text: profile?.location?.country ?? '');
    _zip = TextEditingController(text: profile?.location?.postalCode ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _zip.dispose();
    super.dispose();
  }

  void _save() {
    if (_profileId.isEmpty) return;
    context.read<ProfileBloc>().add(
      UpdateBusinessProfileRequested(
        BusinessProfileUpdate(
          profileId: _profileId,
          businessName: _name.text.trim(),
          category: _category.text.trim(),
          description: _description.text.trim(),
          street: _street.text.trim(),
          city: _city.text.trim(),
          state: _state.text.trim(),
          country: _country.text.trim(),
          zipCode: _zip.text.trim(),
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
          if (state.actionMessage != null) {
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Field(label: 'Nombre comercial', controller: _name),
                _Field(label: 'Categoria', controller: _category),
                _Field(
                  label: 'Descripcion',
                  controller: _description,
                  maxLines: 3,
                ),
                _Field(label: 'Direccion', controller: _street),
                _Field(label: 'Ciudad', controller: _city),
                _Field(label: 'Estado', controller: _state),
                _Field(label: 'Pais', controller: _country),
                _Field(label: 'Codigo postal', controller: _zip),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
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
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
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
        ),
      ),
    );
  }
}
