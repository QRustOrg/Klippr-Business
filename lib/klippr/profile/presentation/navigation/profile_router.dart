import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/bloc/profile_bloc.dart';
import '../views/edit_profile_screen.dart';
import '../views/profile_screen.dart';

abstract final class ProfileRouter {
  static Route<void> profile(ProfileBloc bloc) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: const ProfileScreen(),
      ),
    );
  }

  static Route<void> edit(ProfileBloc bloc) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: const EditProfileScreen(),
      ),
    );
  }
}
