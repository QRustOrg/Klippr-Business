import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../promotions/presentation/navigation/promotions_router.dart';
import '../../../promotions/presentation/views/promo_colors.dart';
import '../../application/bloc/profile_bloc.dart';
import '../../application/bloc/profile_event.dart';
import '../../application/bloc/profile_state.dart';
import '../../domain/models/business_profile_update.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _country = TextEditingController();
  final _zip = TextEditingController();
  String _profileId = '';

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadBusinessProfile());
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
    if (_profileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil aún no cargado. Espera un momento e intenta de nuevo.'),
          backgroundColor: Colors.orange,
        ),
      );
      context.read<ProfileBloc>().add(const LoadBusinessProfile());
      return;
    }

    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre comercial es obligatorio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<ProfileBloc>().add(
      UpdateBusinessProfileRequested(
        BusinessProfileUpdate(
          profileId: _profileId,
          businessName: _name.text.trim(),
          category: _category.text.trim().isEmpty ? null : _category.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          street: _street.text.trim().isEmpty ? null : _street.text.trim(),
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
          state: _state.text.trim().isEmpty ? null : _state.text.trim(),
          country: _country.text.trim().isEmpty ? null : _country.text.trim(),
          zipCode: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
        ),
      ),
    );
  }

  void _skip() {
    Navigator.of(context).pushReplacement(PromotionsRouter.home());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PromoColors.screenBg,
      appBar: AppBar(
        backgroundColor: PromoColors.purple,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Completa tu perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Omitir',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.profile != null && _profileId.isEmpty) {
            setState(() {
              _profileId = state.profile!.id.value;
              if (_name.text.isEmpty) {
                _name.text = state.profile!.businessName;
              }
              if (_category.text.isEmpty) {
                _category.text = state.profile!.category?.name ?? '';
              }
              if (_description.text.isEmpty) {
                _description.text = state.profile!.description ?? '';
              }
              if (_street.text.isEmpty) {
                _street.text = state.profile!.location?.street ?? '';
              }
              if (_city.text.isEmpty) {
                _city.text = state.profile!.location?.city ?? '';
              }
              if (_state.text.isEmpty) {
                _state.text = state.profile!.location?.state ?? '';
              }
              if (_country.text.isEmpty) {
                _country.text = state.profile!.location?.country ?? '';
              }
              if (_zip.text.isEmpty) {
                _zip.text = state.profile!.location?.postalCode ?? '';
              }
            });
          }
          if (state.actionMessage != null && state.error == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage!),
                backgroundColor: PromoColors.purple,
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                Navigator.of(context).pushReplacement(PromotionsRouter.home());
              }
            });
          }
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.profile == null) {
            return const Center(
              child: CircularProgressIndicator(color: PromoColors.purple),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuéntanos sobre tu negocio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PromoColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta información ayudará a los clientes a conocerte mejor.',
                  style: TextStyle(color: PromoColors.textGray, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _Field(label: 'Nombre comercial *', controller: _name),
                _Field(label: 'Categoría', controller: _category),
                _Field(
                  label: 'Descripción',
                  controller: _description,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ubicación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PromoColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _Field(label: 'Dirección', controller: _street),
                _Field(label: 'Ciudad', controller: _city),
                _Field(label: 'Estado/Provincia', controller: _state),
                _Field(label: 'País', controller: _country),
                _Field(label: 'Código postal', controller: _zip),
                const SizedBox(height: 24),
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
                            'Guardar y continuar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
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
